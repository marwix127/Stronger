import { after, before, beforeEach, describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const currentDirectory = dirname(fileURLToPath(import.meta.url));
const rules = readFileSync(
  resolve(currentDirectory, '..', 'firestore.rules'),
  'utf8',
);

let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId: 'stronger-rules-test',
    firestore: { rules },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

async function seed(path, data) {
  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

describe('user-owned data', () => {
  test('rejects anonymous access', async () => {
    const anonymous = () => testEnvironment.unauthenticatedContext().firestore();

    await assertFails(getDoc(doc(anonymous(), 'users/user-1')));
    await assertFails(
      setDoc(doc(anonymous(), 'users/user-1/trainings/training-1'), {
        name: 'Pierna',
      }),
    );
  });

  test('allows a user to manage every Stronger subcollection they own', async () => {
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();
    const paths = [
      'users/user-1/trainings/training-1',
      'users/user-1/body_measurements/measurement-1',
      'users/user-1/muscle_data/scores',
    ];

    for (const path of paths) {
      await assertSucceeds(setDoc(doc(firestore, path), { value: 1 }));
      await assertSucceeds(getDoc(doc(firestore, path)));
      await assertSucceeds(updateDoc(doc(firestore, path), { value: 2 }));
      await assertSucceeds(deleteDoc(doc(firestore, path)));
    }
  });

  test('prevents one user from reading or writing another user data', async () => {
    await seed('users/user-2/trainings/private-training', { name: 'Private' });
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();
    const foreignDocument = doc(
      firestore,
      'users/user-2/trainings/private-training',
    );

    await assertFails(getDoc(foreignDocument));
    await assertFails(setDoc(foreignDocument, { name: 'Attack' }));
    await assertFails(deleteDoc(foreignDocument));
  });
});

describe('exercise catalogue', () => {
  beforeEach(async () => {
    await seed('ejercicios2/global', {
      nombre: 'Sentadilla',
      categoria: 'Piernas',
      esPersonalizado: false,
      uid: null,
    });
    await seed('ejercicios2/user-1-exercise', {
      nombre: 'Mi ejercicio',
      categoria: 'Personal',
      esPersonalizado: true,
      uid: 'user-1',
    });
    await seed('ejercicios2/user-2-exercise', {
      nombre: 'Ejercicio ajeno',
      categoria: 'Privado',
      esPersonalizado: true,
      uid: 'user-2',
    });
  });

  test('allows authenticated users to query the shared catalogue', async () => {
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();
    const snapshot = await assertSucceeds(
      getDocs(
        query(
          collection(firestore, 'ejercicios2'),
          where('esPersonalizado', '==', false),
        ),
      ),
    );

    assert.equal(snapshot.size, 1);
    assert.equal(snapshot.docs[0].id, 'global');
  });

  test('allows users to query only their personal exercises', async () => {
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();
    const snapshot = await assertSucceeds(
      getDocs(
        query(
          collection(firestore, 'ejercicios2'),
          where('uid', '==', 'user-1'),
        ),
      ),
    );

    assert.deepEqual(snapshot.docs.map((document) => document.id), [
      'user-1-exercise',
    ]);
    await assertFails(getDocs(collection(firestore, 'ejercicios2')));
  });

  test('requires the authenticated uid when creating a personal exercise', async () => {
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();

    await assertSucceeds(
      setDoc(doc(firestore, 'ejercicios2/new-personal'), {
        nombre: 'Nuevo',
        categoria: 'Personal',
        esPersonalizado: true,
        uid: 'user-1',
      }),
    );
    await assertFails(
      setDoc(doc(firestore, 'ejercicios2/forged-owner'), {
        nombre: 'Ataque',
        categoria: 'Personal',
        esPersonalizado: true,
        uid: 'user-2',
      }),
    );
    await assertFails(
      setDoc(doc(firestore, 'ejercicios2/forged-global'), {
        nombre: 'Global falso',
        categoria: 'Personal',
        esPersonalizado: false,
        uid: null,
      }),
    );
  });

  test('only the owner can update or delete a personal exercise', async () => {
    const owner = testEnvironment.authenticatedContext('user-1').firestore();
    const stranger = testEnvironment.authenticatedContext('user-2').firestore();
    const ownerReference = doc(owner, 'ejercicios2/user-1-exercise');
    const strangerReference = doc(stranger, 'ejercicios2/user-1-exercise');

    await assertSucceeds(updateDoc(ownerReference, { nombre: 'Actualizado' }));
    await assertFails(updateDoc(strangerReference, { nombre: 'Ataque' }));
    await assertFails(deleteDoc(strangerReference));
    await assertSucceeds(deleteDoc(ownerReference));
  });

  test('prevents changing ownership or modifying shared exercises', async () => {
    const firestore = testEnvironment.authenticatedContext('user-1').firestore();

    await assertFails(
      updateDoc(doc(firestore, 'ejercicios2/user-1-exercise'), {
        uid: 'user-2',
      }),
    );
    await assertFails(
      updateDoc(doc(firestore, 'ejercicios2/user-1-exercise'), {
        esPersonalizado: false,
      }),
    );
    await assertFails(
      updateDoc(doc(firestore, 'ejercicios2/global'), { nombre: 'Alterado' }),
    );
    await assertFails(deleteDoc(doc(firestore, 'ejercicios2/global')));
  });

  test('rejects anonymous catalogue reads', async () => {
    const firestore = testEnvironment.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(firestore, 'ejercicios2/global')));
  });
});
