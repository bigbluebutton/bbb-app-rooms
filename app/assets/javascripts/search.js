// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
//
// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
//
// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.
//
// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

// Set data-search="recordings" on the search input.
// Set data-search-table="#recording-table" on the search input pointing to the table.
// Set data-search-target="1" on the table being searched.
// Set data-search-field="1" on the elements inside the table that should be searched.
// Adds the class 'search-hidden' to <tr> elements to hide them.

$(document).on('turbolinks:load', function(){

  $('[data-search=recordings]').each(function(){
    $input = $(this);

    // in case there's already something in the input
    filterRecordings($input);

    $input.on("keyup", function(event){
      filterRecordings($input);
    });
  });

});

var filterRecordings = function($input) {
  // Retrieve the current search query
  var query = $input.val().match(/\S+/g);
  var matcher = null;
  if (query !== null) {
    matcher = new RegExp(query.join('|'), 'gi');
  }

  // Search for recordings and display them based on name match
  var recordingsFound = 0;

  recordings = $($input.data('search-table')).find('tr');
  recordings.each(function(){
    var searchContent = $(this).find('[data-search-field]').text();
    if(matcher === null || searchContent.match(matcher)){
      recordingsFound = recordingsFound + 1;
      $(this).removeClass('search-hidden');
    }
    else{
      $(this).addClass('search-hidden');
    }
  });

  // Show "No recordings match your search" if no recordings found
  if(query !== null && recordingsFound === 0){
    $input.addClass('is-invalid');
  }
  else{
    $input.removeClass('is-invalid');
  }
};
