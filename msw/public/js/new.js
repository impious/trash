$('#formid').submit(function( event ) {
  if ( $("#name").val().length == 0 ||  $("#url").val().length == 0 )
  {
    alert('Invalid data.');
    event.preventDefault();
  }
  if($("#name").val().length > 20)
  {
    alert('Smaller name. Kthxbye.');
    event.preventDefault();
  }
  if($("#url").val().length > 50)
  {
    alert('Smaller or invalid url. Kthxbye.');
    event.preventDefault();
  }

});
