/**
 * Asserts "expected" versus "actual",
 * 'failing' the assertion (via Error) if a difference is found.
 *
 * @param {String} message The comparison message passed by the user
 * @param {*} expected The expected item
 * @param {*} actual The actual item
 */
function assertEquals (message, expected, actual) {
  try {
    _assertEquals(expected, actual);
  } catch (error) {
    throw new Error(message + ' Expected ' + error.message);
  }
  function _assertEquals (expected, actual) {
    var i,
      ii,
      divider;
    // copy of itself
    if (expected === actual) {
      return;
    }
  // different types
    if (typeof expected !== typeof actual) {
      emitTypeError(expected, actual);
    }
    // primitive, use strict comparing
    if (isPrimitive(expected) && expected !== actual) {
      throw new Error('"' + expected + '" but found "' + actual + '"');
    }
    // null checks
    if (expected === null && actual !== null) {
      emitTypeError(expected, actual);
    }

    if (expected !== null && actual === null) {
      emitTypeError(expected, actual);
    }
    // Arrays
    if (Array.isArray(expected) === true && Array.isArray(actual) === true) {
      // different lengths
      if (expected.length !== actual.length) {
        throw new Error('Array length ' + expected.length + ' but found ' + actual.length);
      }
      for (i = 0, ii = expected.length; i < ii; i++) {
        try {
          _assertEquals(expected[i], actual[i]);
        } catch (error) {
          divider = isPrimitive(expected[i]) ? ' ' : Array.isArray(expected[i]) ? '' : '.';
          throw new Error('[' + i + ']' + divider + error.message);
        }
      }
    } else if (Array.isArray(expected) && !Array.isArray(actual)) {
      emitTypeError(expected, actual);
    } else if (!Array.isArray(expected) && Array.isArray(actual)) {
      emitTypeError(expected, actual);
    } else if (typeof expected === 'object') {
      for (i in expected) {
        if (expected.hasOwnProperty(i)) {
          // check missed prop
          if (!actual.hasOwnProperty(i)) {
            throw new Error(i + ' but was not found');
          }
          try {
            _assertEquals(expected[i], actual[i]);
          } catch (error) {
            divider = isPrimitive(expected[i]) ? ' ' : Array.isArray(expected[i]) ? '' : '.';
            throw new Error(i + divider + error.message);
          }
        }
      }
      // try to find extra prop
      for (i in actual) {
        if (actual.hasOwnProperty(i)) {
          if (!expected.hasOwnProperty(i)) {
            throw new Error(i + ' to be missing but was found');
          }
        }
      }
    }
  }
  function isPrimitive (expected) {
    return typeof expected === 'string' || typeof expected === 'number' || typeof expected === 'boolean';
  }
  function emitTypeError (expected, actual) {
    throw new Error('type ' + getTypeName(expected) + ' but found type ' + getTypeName(actual));
  }
  function getTypeName (value) {
    return Array.isArray(value) ? 'Array' : typeof value === 'object' ? value === null ? 'null' : 'Object' : typeof value;
  }
}

/* -- Test running code:  --- */

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

    // Run the tests
  var assertionFailures = [];
  runTest('Test 01: ', assertionFailures, 'abc', 'abc');//
  runTest('Test 02: ', assertionFailures, 'abcdef', 'abc');
  runTest('Test 03: ', assertionFailures, ['a'], {0: 'a'});
  runTest('Test 04: ', assertionFailures, ['a', 'b'], ['a', 'b', 'c']);
  runTest('Test 05: ', assertionFailures, ['a', 'b', 'c'], ['a', 'b', 'c']);//
  runTest('Test 06: ', assertionFailures, complexObject1, complexObject1Copy);//
  runTest('Test 07: ', assertionFailures, complexObject1, complexObject2);
  runTest('Test 08: ', assertionFailures, complexObject1, complexObject3);
  runTest('Test 09: ', assertionFailures, null, {});
  runTest('Test 10: ', assertionFailures, complexObject3, complexObject1);
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
