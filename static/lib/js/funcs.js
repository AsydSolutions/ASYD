$(function() {

  $(window).scroll(function(e) {
    // Get the position of the location where the scroller starts.
    var scroller_anchor = $(".scroller_anchor").offset().top;

    // Check if the user has scrolled and the current position is after the scroller start location and if its not already fixed at the top
    if ($(this).scrollTop() >= scroller_anchor && $('.subnavbar-fixed-top').css('position') != 'fixed')
    {    // Change the CSS of the scroller to hilight it and fix it at the top of the screen.
        $('.subnavbar-fixed-top').css({
            'left': '0',
            'right': '0',
            'position': 'fixed',
            'z-index': '2048',
            'top': '0'
        });
        // Changing the height of the scroller anchor to that of scroller so that there is no change in the overall height of the page.
        $('.scroller_anchor').css('height', '50px');
    }
    else if ($(this).scrollTop() < scroller_anchor && $('.subnavbar-fixed-top').css('position') != 'relative')
    {    // If the user has scrolled back to the location above the scroller anchor place it back into the content.

        // Change the height of the scroller anchor to 0 and now we will be adding the scroller back to the content.
        $('.scroller_anchor').css('height', '0px');

        // Change the CSS and put it back to its original position.
        $('.subnavbar-fixed-top').css({
            'position': 'relative'
        });
    }
  });

  $("#add").click(function() {
    $("#add_form").toggle(); $("#add").remove();
  });

  $(".import_key").click(function() {
    $("#import").toggle();
  });

  $(".import_key").click(function() {
    $("#gen").toggle();
  });

  $('.hint').tooltip();

  $('a[deploy-confirm]').click(function(ev) {
    var dep = $(this).attr('href');
    var e = document.getElementById('selectHostDeploy');
    var target = e.options[e.selectedIndex].value;
    if (!target) {
      return false;
    }
    var host = target.split(";");
    if (!$('#dataConfirmModal').length) {
      $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="deployForm" action="/deploys/deploy" method="post"><input type="hidden" name="deploy" value="'+dep+'"><input type="hidden" name="target" value="'+target+'"><button class="btn" data-dismiss="modal" aria-hidden="true">Cancel</button><button type="submit" class="btn btn-primary">Deploy!</a></div></div>');
    }
    $('#dataConfirmModal').find('.modal-body').text($(this).attr('deploy-confirm')+host[0]+" "+host[1]+"?");
    $('#dataConfirmModal').modal({show:true});
    return false;
  });

  $(document).ready(function() {
    var dttbl = $('script[src="/lib/js/datatables-bootstrap.js"]').length;
    var slct = $('script[src="/lib/js/select2.min.js"]').length;
    if (dttbl != 0) {
				$('#hgtable').dataTable( {
            "ordering": false,
            "lengthChange": false,
            "pageLength": 15,
            "info": false,
            renderer: "bootstrap",
            "language": {
              search: "<i class=\"icon-search\"></i>",
              "emptyTable": "You haven't added any hostgroup yet",
              "paginate": {
                "next": "<i class=\"icon-arrow-right\"></i>",
                "previous": "<i class=\"icon-arrow-left\"></i>"
              }
            }
        });
        $('#htable').dataTable( {
            "ordering": false,
            "lengthChange": false,
            "pageLength": 10,
            "info": false,
            renderer: "bootstrap",
            "language": {
              search: "<i class=\"icon-search\"></i>",
              "emptyTable": "You haven't added any host yet",
              "paginate": {
                "next": "<i class=\"icon-arrow-right\"></i>",
                "previous": "<i class=\"icon-arrow-left\"></i>"
              }
            }
        });
        $('#hgmtable').dataTable( {
            "ordering": false,
            "lengthChange": false,
            "pageLength": 10,
            "info": false,
            renderer: "bootstrap",
            "language": {
              search: "<i class=\"icon-search\"></i>",
              "emptyTable": "You haven't added any members to this group yet",
              "paginate": {
                "next": "<i class=\"icon-arrow-right\"></i>",
                "previous": "<i class=\"icon-arrow-left\"></i>"
              }
            }
        });
        $('#dptable').dataTable( {
            "ordering": false,
            "lengthChange": false,
            "pageLength": 10,
            "info": false,
            renderer: "bootstrap",
            "language": {
              search: "<i class=\"icon-search\"></i>",
              "emptyTable": "You haven't added any deploys yet",
              "paginate": {
                "next": "<i class=\"icon-arrow-right\"></i>",
                "previous": "<i class=\"icon-arrow-left\"></i>"
              }
            }
        });
      };
      if (slct != 0) {
        $("#selectMember").select2( {
          "placeholder": "Select host",
        });
        $("#selectHostDeploy").select2( {
          "placeholder": "Select host or hostgroup",
        });
        $("#selectHostInstall").select2( {
          "placeholder": "Select host or hostgroup",
        });
      };
	});

  $("input,select,textarea").not("[type=submit]").jqBootstrapValidation();

  $('div.btn-group[data-toggle-name=*]').each(function(){
    var group   = $(this);
    var form    = group.parents('form').eq(0);
    var name    = group.attr('data-toggle-name');
    var hidden  = $('input[name="' + name + '"]', form);
    $('button', group).each(function(){
      var button = $(this);
      button.live('click', function(){
          hidden.val($(this).val());
      });
      if(button.val() == hidden.val()) {
        button.addClass('active');
      }
    });
  });
});

function passDataToModal(data, modal_id) {
  $(".modal-body #dataInput").text(data);
  $(".modal-footer #dataInput").val( data );
  $(modal_id).modal('show');
}

function dismissNotification(msg_id)
{
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("POST","/notification/dismiss",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("msg_id=" + msg_id);
}
