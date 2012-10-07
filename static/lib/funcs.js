$(function() {
  $("#add").click(function() {
    $("#add_form").toggle(); $("#add").remove();
  });

  $('.srv').width(
    Math.max.apply(
      Math,
      $('.srv').map(function(){
        return $(this).outerWidth();
      }).get()
    )
  );
});
