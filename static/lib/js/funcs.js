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
            'z-index': '100',
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
    var dep = $(this).attr('data-deploy');
    var e = document.getElementById('selectHostDeploy');
    var target = e.options[e.selectedIndex].value;
    if (!target) {
      return false;
    }
    var host = target.split(";");
    if (!$('#dataConfirmModal').length) {
      $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="deployForm" action="/deploys/deploy" method="post"><input type="hidden" name="deploy" value="'+dep+'"><input type="hidden" name="target" value="'+target+'"><button class="btn" data-dismiss="modal" aria-hidden="true">Cancel</button><button type="submit" class="btn btn-primary">Deploy!</a></div></div>');
    }
    if (Modernizr.csstransforms3d == false){
      $('#dataConfirmModal').removeClass('fade');
    };
    var text = $(this).attr('deploy-confirm')+host[0]+" "+host[1]+"?";
    if (document.getElementById('alert_'+dep)){
      text += "<br><strong><h3>Alert:</h3> "+document.getElementById('alert_'+dep).value+"</strong>";
    };
    $('#dataConfirmModal').find('.modal-body').text("");
    $('#dataConfirmModal').find('.modal-body').append(text);
    $('#dataConfirmModal').modal({show:true});
    return false;
  });

  $(document).ready(function() {
    if (Modernizr.csstransforms3d == false){
      $('.modal').removeClass('fade');
    };
    var dttbl = $('script[src="/js/datatables-bootstrap.js"]').length;
    var slct = $('script[src="/js/select2.min.js"]').length;
    if (dttbl != 0) {
				$('#hgtable').dataTable( {
            "ordering": false,
            "pageLength": 10,
            "info": false,
            "sDom": "<'row-fluid'<'span12'f>r>t<'row-fluid'<'span6'l><'span6'p>>",
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
            "pageLength": 10,
            "info": false,
            "sDom": "<'row-fluid'<'span12'f>r>t<'row-fluid'<'span6'l><'span6'p>>",
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
            "pageLength": 10,
            "info": false,
            "sDom": "<'row-fluid'<'span12'f>r>t<'row-fluid'<'span6'l><'span6'p>>",
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
        $('#attable').dataTable( {
            "ordering": false,
            "lengthChange": false,
            "pageLength": 10,
            "info": false,
            "searching": false,
            renderer: "bootstrap",
            "language": {
              "emptyTable": "No active tasks",
              "paginate": {
                "next": "<i class=\"icon-arrow-right\"></i>",
                "previous": "<i class=\"icon-arrow-left\"></i>"
              }
            }
        });
        $('#cttable').dataTable( {
            "ordering": false,
            "pageLength": 5,
            "info": false,
            "searching": false,
            "lengthMenu": [ 5, 10, 25, 50, 75, 100 ],
            "sDom": "<'row-fluid'<'span12'f>r>t<'row-fluid'<'span6'l><'span6'p>>",
            renderer: "bootstrap",
            "language": {
              "emptyTable": "No completed tasks",
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

function editDeploy(path)
{
  $('.CodeMirror').each(function(i, el){
    el.parentNode.removeChild(el);
  });
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("GET","/deploys/get_file_contents/" + path, false);
  xmlhttp.send();
  $('#filePath').html(path);
  $('#editBox').val(xmlhttp.responseText);
  var editor = CodeMirror.fromTextArea(editBox, {
    mode: "text/x-sh"
  });
  editor.on("change", function() {
    editor.save();
  });
}

function saveDeployFile(){
  var path = $("#filePath").text();
  var text = document.getElementById('editBox').value;
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("POST","/deploys/edit",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("path=" + path + "&text=" + text);
  $("#saved").show().delay(2000).fadeOut();
}

function passDataToModal(data, modal_id) {
  $(".modal-body #dataInput").text(data);
  $(".modal-body #dataInput").val( data );
  $(".modal-footer #dataInput").val( data );
  $(modal_id).modal('show');
}

function editTeam(name, div_id) {
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("GET","/team/edit/" + name,false);
  xmlhttp.send();
  document.getElementById('teameditor').innerHTML = xmlhttp.responseText;
  $('#editTeam').modal('show');
}

function getTaskNotifications(task_id) {
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("GET","/notifications/bytask/" + task_id, false);
  xmlhttp.send();
  document.getElementById('taskNotifications').innerHTML = xmlhttp.responseText;
}

function addTeamMember(team) {
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  var e = document.getElementById("selectAddUser");
  var username = e.options[e.selectedIndex].value;
  e.removeChild(e.options[e.selectedIndex]);
  xmlhttp.open("POST","/team/add-member",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("team=" + team + "&username=" + username);
  var newuserhtml = '<div class="input-append" id="' + username + '"><span class="add-on" style="width: 78px;">' + username + '</span><button class="btn" type="button" onclick="delTeamMember(\'' + team + '\', \'' + username + '\')"><i class="icon-minus"></i></button></div>';
  $('#teamMembers').append(newuserhtml);
}

function delTeamMember(team, username) {
  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("POST","/team/del-member",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("team=" + team + "&username=" + username);
  var div = document.getElementById(username);
  div.parentNode.removeChild(div);
  var sel = document.getElementById('selectAddUser');
  var opt = document.createElement('option'); // create new option element
  // create text node to add to option element (opt)
  opt.appendChild( document.createTextNode(username) );
  opt.value = username; // set value property of opt
  sel.appendChild(opt); // add opt to end of select list (sel)
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

function dismissMonitoringNotification(msg_id)
{
  var element = document.getElementById(msg_id);
  element.parentNode.removeChild(element);

  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("POST","/notification/monitoring/dismiss",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("msg_id=" + msg_id);
}

function acknowledgeMonitoringNotification(msg_id)
{
  var element = document.getElementById(msg_id);
  element.parentNode.removeChild(element);

  var xmlhttp;
  if (window.XMLHttpRequest)
  {// code for IE7+, Firefox, Chrome, Opera, Safari
    xmlhttp=new XMLHttpRequest();
  }
  else
  {// code for IE6, IE5
    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
  xmlhttp.open("POST","/notification/monitoring/acknowledge",true);
  xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xmlhttp.send("msg_id=" + msg_id);
}
