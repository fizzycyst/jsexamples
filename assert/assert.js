/**
 * Asserts "expected" versus "actual",
 * 'failing' the assertion (via Error) if a difference is found.
 *
 * @param {String} message The comparison message passed by the user
 * @param {*} expected The expected item
 * @param {*} actual The actual item
 */
 /*
  * Break out the functions needed and put them at the top of the script.
  *
  * Function to check for primitives which is called a few times
  *
  * Function to generate error meesages for type mismatches
  *
  * Function to get the name of the type of object for messaging purposes.
  *
  * Function to deal with arrays as it's quite involved
  *
  * Function to deal with objects and the properties within.
  *
  * secondary function called by the main function that then does all the main work
  */

 function isPrimitive (expected) {
   // Ignoring null, undefined and symbol for our purposes.
   if (typeof expected === 'string' || typeof expected === 'number' || typeof expected === 'boolean') {
     return true;
   } else {
     return false;
   }
 }

 function getTypeName (value) {
   // What type of object do we have?
   return Array.isArray(value) ? 'Array' : typeof value === 'object' ? value === null ? 'null' : 'Object' : typeof value;
 }

 function generateTypeError (expected, actual) {
   // Create an error if we have a type mismatch and return a human readable message.
   throw new Error('type ' + getTypeName(expected) + ' but found type ' + getTypeName(actual));
 }

 // Break out the Array and Object checks into functions for more modular approach.

 function checkArray (expected, actual) {
   if (Array.isArray(expected) === true && Array.isArray(actual) === true) {
     if (expected.length !== actual.length) {
       throw new Error('array length ' + expected.length + ' but found ' + actual.length);
     }
     let arrayLength = expected.length;
     for (var index = 0; index < arrayLength; index++) {
       try {
         _assertEquals(expected[index], actual[index]);
       } catch (error) {
         let delimiter = isPrimitive(expected[index]) ? ' ' : Array.isArray(expected[index]) ? '' : '.';
         throw new Error('[' + index + ']' + delimiter + error.message);
       }
     }
   } else if (Array.isArray(expected) && !Array.isArray(actual)) {
     generateTypeError(expected, actual);
   } else if (!Array.isArray(expected) && Array.isArray(actual)) {
     generateTypeError(expected, actual);
   }
 }

 function checkObject (expected, actual) {
   // Checking that object properties match.
   var index;
   if (typeof expected === 'object') {
     for (index in expected) {
       if (expected.hasOwnProperty(index)) {
         if (!actual.hasOwnProperty(index)) {
           throw new Error(index + ' but was not found');
         }
         try {
           _assertEquals(expected[index], actual[index]);
         } catch (error) {
           let delimiter = isPrimitive(expected[index]) ? ' ' : Array.isArray(expected[index]) ? '' : '.';
           throw new Error(index + delimiter + error.message);
         }
       }
     }
     for (index in actual) {
       if (actual.hasOwnProperty(index)) {
         if (!expected.hasOwnProperty(index)) {
           throw new Error(index + ' to be missing but was found');
         }
       }
     }
   }
 }

 function _assertEquals (expected, actual) {
  // Private funtion to do the actual work.

   if (expected === actual) {
     // If the expected results match the actual return -- no more work to do.
     return;
   }
   // If our types do not match.
   if (typeof expected !== typeof actual) {
     generateTypeError(expected, actual);
   }
   if (isPrimitive(expected) && expected !== actual) {
     throw new Error('"' + expected + '" but found "' + actual + '"');
   }
   if (expected === null && actual !== null) {
     generateTypeError(expected, actual);
   }
   if (!expected !== null && actual === null) {
     generateTypeError(expected, actual);
   }

   checkArray(expected, actual);
   checkObject(expected, actual);
 }

 function assertEquals (message, expected, actual) {
   try {
     _assertEquals(expected, actual);
   } catch (error) {
     throw new Error(message + ' Expected  ' + error.message);
   }
 }
 /**
 * Runs a "assertEquals" test.
 *
 * @param {String} message The initial message to pass
 * @param {Array} assertionFailures List of messages that will be displayed on the UI for evaluation
 * @param {*} expected Expected item
 * @param {*} actual The actual item
 */
 function runTest (message, assertionFailures, expected, actual) {
   try {
     assertEquals(message, expected, actual);
   } catch (failure) {
     assertionFailures.push(failure.message);
   }
 }

 function runAll () {
   var complexObject1 = {
     propA: 1,
     propB: {
       propA: [1, { propA: 'a', propB: 'b' }, 3],
       propB: 1,
       propC: 2
     }
   };
   var complexObject1Copy = {
     propA: 1,
     propB: {
       propA: [1, { propA: 'a', propB: 'b' }, 3],
       propB: 1,
       propC: 2
     }
   };
   var complexObject2 = {
     propA: 1,
     propB: {
       propB: 1,
       propA: [1, { propA: 'a', propB: 'c' }, 3],
       propC: 2
     }
   };
   var complexObject3 = {
     propA: 1,
     propB: {
       propA: [1, { propA: 'a', propB: 'b' }, 3],
       propB: 1
     }
   };
   var complexObject4 = {
     propA: 1,
     propB: {
       propA: [1, { propA: 'a', propB: 'b' }, 3],
       propB: 1
     },
     propC: 'Extra'
   };

   // Run the tests
   var assertionFailures = [];
   runTest('Test 01: ', assertionFailures, 'abc', 'abc');
   runTest('Test 02: ', assertionFailures, 'abcdef', 'abc');
   runTest('Test 03: ', assertionFailures, ['a'], {0: 'a'});
   runTest('Test 04: ', assertionFailures, ['a', 'b'], ['a', 'b', 'c']);
   runTest('Test 05: ', assertionFailures, ['a', 'b', 'c'], ['a', 'b', 'c']);
   runTest('Test 06: ', assertionFailures, complexObject1, complexObject1Copy);
   runTest('Test 07: ', assertionFailures, complexObject1, complexObject2);
   runTest('Test 08: ', assertionFailures, complexObject1, complexObject3);
   runTest('Test 09: ', assertionFailures, null, {});
   runTest('Test 10: ', assertionFailures, complexObject3, complexObject4);

   // Output the results
   var messagesEl = document.getElementById('messages');
   var newListEl;
   var i, ii;

   for (i = 0, ii = assertionFailures.length; i < ii; i++) {
     newListEl = document.createElement('li');
     newListEl.innerHTML = assertionFailures[i];
     messagesEl.appendChild(newListEl);
   }
 }
 runAll();
