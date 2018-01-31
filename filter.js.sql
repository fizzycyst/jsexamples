function getTableAndRows() {

    // Quick function to get the rows from a given table.
    // Saves doing this in every function in this code...

    var table,tr;

    table = document.getElementById("mainTable");
    tr = table.getElementsByTagName("tr");

    return (table,tr);
}

function setupSelect(column) {

//This code will get all the distinct data in a column in a given table.
// and create a select in the header so it can be searched on it.


// Update July 2017 to fix bug that caused intermittent issues
// with selects not being created.

// Use a Regular Expression to find any text on Buttons with forms that
// the regular text search is missing.
// trim and whip out any non breaking spaces that stop the non button text
// matching with the button text.
// Regular Expression also has to account for the fact that different browsers
// render the buttons differently Firefox and chrome reverse the syntax of the
// HTML.

// PG -- July 2017

    var searchColumn = "select" + column;

    var targetSelect = document.getElementById(searchColumn);
    var table,tr = getTableAndRows();
    var uniqueElements = {};
    var option = document.createElement("option");


    var td;
    for (i=1; i< tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[column];
        var tdHTML = td.innerHTML.split("&nbsp"); // remove any trailing non breaking spaces.
        if (tdHTML[0].includes("<form")){
            var myregex = /(\<input value=\"|\<input type=\"submit\" value=\")(.*?)(\"\s+type=\"submit|\"\>\s+)/i; // upgated regex for crossbrowser support.
            uniqueElements[tdHTML[0].match(myregex)[2].trim()] = "x";
        } else {

            uniqueElements[tdHTML[0].trim()] = "x"; // normal text
        }
    }

    option = document.createElement("option");
    option.text = "All";
    option.value="";
    targetSelect.add(option);
    //Object.keys(uniqueElements).sort().forEach(function(key){
   for (var key in uniqueElements) {


  option = document.createElement("option");
   var tmp = key.split("&nbsp"); // drop non breaking spaces
   console.log(tmp[0]);
   if (tmp[0].includes("<form")){
       alert(tmp[0]);
       //var myregex = /\<input\ value\=\"(.*?)\"\s+type\=\"submit/i;  // button text
       var myregex = /(\<input value=\"|\<input type=\"submit\" value=\")(.*?)(\"\s+type=\"submit|\"\>\s+)/i; // updated regex for crossbrowser support.
       var myresult = myregex.exec(tmp[0]);
       
      // option.text=tmp[0].match(myregex)[2]; // the [2] gets the bit the brackets within the Regex... otherwise you match the whole thing which is not what we want here
       //option.value=tmp[0].match(myregex)[2];
   } else {
       option.text = tmp[0];
       option.value= tmp[0];


   }
         targetSelect.add(option);
   }

    document.getElementById(searchColumn).classList.remove("rowInvisible");
    document.getElementById(searchColumn).setAttribute("onchange","selectSearch(" + column+ ")");
}


function selectSearch(column) {

    // To trigger a search using a select drop down we have to copy the selected item
    // into a hidden text field and then trigger a standard search.

    var searchColumn = "select" + column;
    var searchField = document.getElementById(searchColumn);
    var searchTerm = searchField.options[searchField.selectedIndex].value;

    document.getElementById(column).value = searchTerm;

    getSearches();

}

function searchFunction(searchText,column) {

    // Main search funtion -- goes through every row in a column looking
    // for the required text.

    var rows = [0];


  var input, filter, table, tr, td, i,foundRows = [];
  input = document.getElementById(column);
  filter = input.value.toUpperCase();

  table,tr = getTableAndRows();

  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[column];
    if (td) {

      // Following is needed for the select/option where conditional search was picking up unconditionals
      // this trims down the search and ensures that this field checks only for an exact search
      // BUT only for this column.
      // PG -- July 2017

   if (column === 7) {
        var newregex = new RegExp(input.value);

        if (td.innerHTML.match(newregex)) {

        //if (td.innerHTML.split("&nbsp")[0].toUpperCase().trim() == filter.trim()) {
        foundRows.push(i);
        }
      } else {
      if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
                 if (filter !== ""){
                    foundRows.push(i);
                }

      }
    }

    }
  }

  if (filter === ""){

      return null ;
  } else {
  return foundRows;
  }
}


function resetTable() {

    // Reset function -- makes everything visible again so new searches can start afresh.

    var inputs = document.getElementsByClassName("textInput");


    var table,tr = getTableAndRows();

    for(i = 1; i< tr.length ;i++) {

        tr[i].classList.remove("rowInvisible");
        tr[i].style.backgroundColor = "";
    }

}

function clearField (column) {
    //This clears the fiels of text when the little "x" is clicked"
    //PG July 2017
    document.getElementById(column).value="";
    getSearches();

}
function getSearches() {

    // Reset the table -- show all the rows and reset the search parameters

    resetTable();

    // Find all the columns and which ones are not empty

    var inputs = document.getElementsByClassName("textInput");
    var combText = "";
    for (j = 0; j < inputs.length; j ++) {
        combText = combText + inputs[j].value;
    }

    if (combText === "" ) {

        return 0;
    }

    var results = [];
    var intersected =[];
    var tableRows = {};
    var mySearches = document.getElementsByClassName("textInput");


    for (i = 0; i < mySearches.length; i++) {

     // do a search....

    results = searchFunction(i,i);

    if (results === null) {
        // If any fields are blank ignore them so they dont affect the search results

        } else {

    intersected.push(results);
    }

    }

    var table,tr = getTableAndRows();

    // This is the clever bit -- merging the arrays into one and returning only the rows that are the same in each!
    // Slightly dumbed down version so IE can cope.

    var result = intersected.shift().filter(function(v) {
    return intersected.every(function(a) {
        return a.indexOf(v) !== -1;
        });
    });

    result.forEach(function(row){

        tableRows[row] ="x";
    });


     var colourCount = 0;
    for (var k = 1; k < tr.length; k++) {

        if (!tableRows[k]) {
           tr[k].classList.add("rowInvisible");
        } else {
             tr[k].classList.remove("rowInvisible");
                colourCount++;
            /*
                Using a simple counter and modulo arithmetic we put back the
                alternating colours when the searches are complete to give the grid effect.
                PG -- July 2017
            */
                if (colourCount % 2 == 0){
             tr[k].style.backgroundColor="white";
                } else {
                    tr[k].style.backgroundColor="#eee";
                }
        }
    }

}
 window.onload = function () {

        // This function sets up the search form when the page loads.


        // First Add an ID attribute to the table so that everything that comes afterwards
        // can work.

        var getmainTable =  document.getElementsByClassName("dataentrytable");
        for ( var i = 0; i < getmainTable.length; i++) {
            getmainTable[i].setAttribute("id","mainTable");
        }

        // The following JSON object contains the hardcoded HTML for every column -- this will need to be updated if
        // and when the table ever changes there is no real choice here as no easy way to get this info into the javascript
        // programatically.

        // The underscores are spacers to align the search windows where there is only one line of text in the header row.



        // REMEMBER -- NB!!!! -- Escape ALL Inverted commas within the html or the page will fail !!!
if (!String.prototype.includes) {
     String.prototype.includes = function() {
        
         return String.prototype.indexOf.apply(this, arguments) !== -1;
     };
 }
 

    var searchFieldSetup = {
"0": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"0\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"0\")></span>"
},
"1": {
  "html": "<input type=\"text\" class=\"textInput rowInvisible\" id=\"1\">"
},
"2": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"2\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"2\")></span>"
},
"3": {
  "html": "<hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"3\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"3\")></span>"
},
"4": {
  "html": "<input type=\"text\" class=\"textInput rowInvisible\" id=\"4\">"
},
"5": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\"class=\"textInput\" id=\"5\"><span class=\"ico ico-mglass\"></span></span><span class=\"close\" onclick=clearField(\"5\")></span>"
},
"6": {
  "html": "<hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"6\"><select id =\"select6\" class=\"rowInvisible\">"
},
"7": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"7\"><select id =\"select7\"  class=\"rowInvisible\">"
},
"8": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" class=\"textInput rowInvisible\" id=\"8\"><select id =\"select8\"  class=\"rowInvisible\">"
},
"9": {
  "html": "<div style=\"color:#E3E5EE\">______</div><hr /><input type=\"text\" autocomplete=\"off\" onkeyup=\"getSearches()\" class=\"textInput\" id=\"9\"><span class=\"ico ico-mglass\"></span><span class=\"close\" onclick=clearField(\"9\")></span>"
}
};


    var tableHeaders = document.getElementsByClassName("deheader");




    for (var k=0; k <tableHeaders.length; k++) {

      tableHeaders[k].innerHTML = tableHeaders[k].innerHTML + searchFieldSetup[k].html;
    }



    // Fill up the drop down menus with the needed data ...

    setupSelect(6); // Column 6
    setupSelect(7); // Column 7
    setupSelect(8); // Column 8 

// Below is the inline style
// For the modifications introducec by this javascript.
// So we do not have to update the overall style sheet.
}