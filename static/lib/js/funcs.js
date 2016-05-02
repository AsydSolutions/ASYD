$(function () {
  $(window).scroll(function () {
    // Get the position of the location where the scroller starts.
    var scroller_anchor = $('.scroller_anchor').offset().top;

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

  $('#add').click(function () {
    $('#add_form').toggle();
    $('#add').remove();
  });

  $('.import_key').click(function () {
    $('#import').toggle();
  });

  $('.import_key').click(function () {
    $('#gen').toggle();
  });

  $('.hint').tooltip();
  if (location.pathname == "/") {
    $('.update-asyd').tooltip('show');
  }

  var flst = $('script[src="/js/bootstrap-filestyle.min.js"]').length;
  if (flst !== 0) {
    $(":file").filestyle({input: false, classButton: "btn input-block-level"});
  }

  $('a[deploy-confirm]').click(function () {
    var dep = $(this).attr('data-deploy');
    var e = document.getElementById('selectHostDeploy');
    var target = e.options[e.selectedIndex].value;
    if (!target) {
      alert('Select a host/hostgroup');
      return false;
    }
    var host = target.split(';');
    if ($('#dataConfirmModal').length) {
      document.getElementById("dataConfirmModal").remove();
    }
    if (!$('#dataConfirmModal').length) {
      $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><a type="button" class="close" data-dismiss="modal" aria-hidden="true">×</a><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="deployForm" action="/deploys/deploy" method="post"><input type="hidden" name="deploy" value="'+dep+'"><input type="hidden" name="target" value="'+target+'"><a class="btn" data-dismiss="modal" aria-hidden="true">Cancel</a><button type="submit" class="btn btn-primary">Deploy!</button></div></div>');
    }
    if (Modernizr.csstransforms3d === false){
      $('#dataConfirmModal').removeClass('fade');
    }
    var text = $(this).attr('deploy-confirm') + host[0] + ' ' + host[1] + '?';
    if ($(this).attr('deploy-alert')) {
      text += '<br /><strong><h3>Alert:</h3> ' + $(this).attr('deploy-alert') + '</strong>';
    }
    $('#dataConfirmModal').find('.modal-body').html(text);
    $('#dataConfirmModal').modal({show:true});
    return false;
  });

  $('a[undeploy-confirm]').click(function () {
    if (!$(this).hasClass('disabled')) {
      var dep = $(this).attr('data-deploy');
      var e = document.getElementById('selectHostDeploy');
      var target = e.options[e.selectedIndex].value;
      if (!target) {
        alert('Select a host/hostgroup');
        return false;
      }
      var host = target.split(';');
      if (!$('#dataConfirmModal').length) {
        $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><a type="button" class="close" data-dismiss="modal" aria-hidden="true">×</a><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="deployForm" action="/deploys/undeploy" method="post"><input type="hidden" name="deploy" value="'+dep+'"><input type="hidden" name="target" value="'+target+'"><a class="btn" data-dismiss="modal" aria-hidden="true">Cancel</a><button type="submit" class="btn btn-primary">Undeploy</button></div></div>');
      }
      if (Modernizr.csstransforms3d === false){
        $('#dataConfirmModal').removeClass('fade');
      }
      var text = $(this).attr('undeploy-confirm') + host[0] + ' ' + host[1] + '?';
      if ($(this).attr('deploy-alert')) {
        text += '<br /><strong><h3>Alert:</h3> ' + $(this).attr('deploy-alert') + '</strong>';
      }
      $('#dataConfirmModal').find('.modal-body').html(text);
      $('#dataConfirmModal').modal({show:true});
      return false;
    }
  });

  $('a[monitor-confirm]').click(function () {
    var mon = $(this).attr('data-monitor');
    var e = document.getElementById('selectHostMonitor');
    var target = e.options[e.selectedIndex].value;
    if (!target) {
      alert('Select a host/hostgroup');
      return false;
    }
    var host = target.split(';');
    if ($('#dataConfirmModal').length) {
      document.getElementById("dataConfirmModal").remove();
    }
    if (!$('#dataConfirmModal').length) {
      $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><a type="button" class="close" data-dismiss="modal" aria-hidden="true">×</a><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="monitorForm" action="/monitors/monitor" method="post"><input type="hidden" name="monitor" value="'+mon+'"><input type="hidden" name="target" value="'+target+'"><a class="btn" data-dismiss="modal" aria-hidden="true">Cancel</a><button type="submit" class="btn btn-primary">Monitor!</button></div></div>');
    }
    if (Modernizr.csstransforms3d === false){
      $('#dataConfirmModal').removeClass('fade');
    }
    var text = $(this).attr('monitor-confirm') + host[0] + ' ' + host[1] + '?';
    $('#dataConfirmModal').find('.modal-body').html(text);
    $('#dataConfirmModal').modal({show:true});
    return false;
  });

  $('a[unmonitor-confirm]').click(function () {
    var mon = $(this).attr('data-monitor');
    var e = document.getElementById('selectHostMonitor');
    var target = e.options[e.selectedIndex].value;
    if (!target) {
      alert('Select a host/hostgroup');
      return false;
    }
    var host = target.split(';');
    if ($('#dataConfirmModal').length) {
      document.getElementById("dataConfirmModal").remove();
    }
    if (!$('#dataConfirmModal').length) {
      $('body').append('<div id="dataConfirmModal" class="modal fade" role="dialog" aria-labelledby="dataConfirmLabel" aria-hidden="true"><div class="modal-header"><a type="button" class="close" data-dismiss="modal" aria-hidden="true">×</a><h3 id="dataConfirmLabel">Please Confirm</h3></div><div class="modal-body"></div><div class="modal-footer"><form id="unmonitorForm" action="/monitors/unmonitor" method="post"><input type="hidden" name="monitor" value="'+mon+'"><input type="hidden" name="target" value="'+target+'"><a class="btn" data-dismiss="modal" aria-hidden="true">Cancel</a><button type="submit" class="btn btn-primary">Un-Monitor!</button></div></div>');
    }
    if (Modernizr.csstransforms3d === false){
      $('#dataConfirmModal').removeClass('fade');
    }
    var text = $(this).attr('unmonitor-confirm') + host[0] + ' ' + host[1] + '?';
    $('#dataConfirmModal').find('.modal-body').html(text);
    $('#dataConfirmModal').modal({show:true});
    return false;
  });

  $(document).ready(function () {
    if (Modernizr.csstransforms3d === false){
      $('.modal').removeClass('fade');
    }
    var hash = window.location.hash;
    if (hash.substring(1) == 'addServer') {
      $('#addServer').modal('show');
      window.location.hash = '';
    }
    var dttbl = $('script[src="/js/datatables-bootstrap.js"]').length;
    var slct = $('script[src="/js/select2.min.js"]').length;
    if (dttbl !== 0) {
      $.extend($.fn.dataTable.defaults, {
        'ordering': false,
        'pageLength': 10,
        'info': false,
        'renderer': 'bootstrap',
        'stateSave': false,
        'language': {
          'search': '<i class="icon-search"></i>',
          'emptyTable': 'You haven\'t added any hostgroup yet',
          'paginate': {
            'next': '<i class="icon-arrow-right"></i>',
            'previous': '<i class="icon-arrow-left"></i>'
          }
        }
      });
      $('#hgtable').dataTable({
        'sDom': '<\'row-fluid\'<\'span12\'f>r>t<\'row-fluid\'<\'span6\'l><\'span6\'p>>',
        'language': {
          'emptyTable': 'You haven\'t added any hostgroup yet'
        }
      });
      $('#htable').dataTable({
        'sDom': '<\'row-fluid\'<\'span12\'f>r>t<\'row-fluid\'<\'span6\'l><\'span6\'p>>',
        'language': {
          'emptyTable': 'You haven\'t added any host yet',
          'stateSave': true
        }
      });
      $('#hgmtable').dataTable({
        'sDom': '<\'row-fluid\'<\'span12\'f>r>t<\'row-fluid\'<\'span6\'l><\'span6\'p>>',
        'language': {
          'emptyTable': 'You haven\'t added any members to this group yet'
        }
      });
      $('#dptable').dataTable({
        'pageLength': 10,
        'language': {
          'emptyTable': 'You haven\'t added any deploys yet'
        }
      });
      $('#montable').dataTable({
        'pageLength': 10,
        'language': {
          'emptyTable': 'You haven\'t added any monitors yet'
        }
      });
      $('#attable').dataTable({
        'lengthChange': false,
        'searching': false,
        'language': {
          'emptyTable': 'No active tasks'
        }
      });
      $('#cttable').dataTable({
        'searching': false,
        'lengthMenu': [ 5, 10, 25, 50, 75, 100 ],
        'sDom': '<\'row-fluid\'<\'span12\'f>r>t<\'row-fluid\'<\'span6\'l><\'span6\'p>>',
        'language': {
          'emptyTable': 'No completed tasks'
        }
      });
    }
    if (slct !== 0) {
      $('#selectMember').select2( {
        'placeholder': 'Select host',
      });
      $('#selectHostDeploy').select2( {
        'placeholder': 'Select host or hostgroup',
      });
      $('#selectHostMonitor').select2( {
        'placeholder': 'Select host or hostgroup',
      });
      $('#selectHostInstall').select2( {
        'placeholder': 'Select host or hostgroup',
      });
      $('#selectHostExecute').select2( {
        'placeholder': 'Select host or hostgroup',
      });
    }
  });

  $('input,select,textarea').not('[type=submit]').jqBootstrapValidation();

  $('div.btn-group[data-toggle-name=*]').each(function () {
    var group   = $(this);
    var form    = group.parents('form').eq(0);
    var name    = group.attr('data-toggle-name');
    var hidden  = $('input[name="' + name + '"]', form);
    $('button', group).each(function () {
      var button = $(this);
      button.live('click', function () {
          hidden.val($(this).val());
      });
      if(button.val() == hidden.val()) {
        button.addClass('active');
      }
    });
  });
});

var editDeploy = function (path)
{
  $('.CodeMirror').each(function (i, el) {
    el.parentNode.removeChild(el);
  });
  $.ajax({url:"/deploys/get_file_contents/" + path, cache: false, async: false, success: function (result) {
    $('#editBox').val(result);
  }});
  $('#filePath').html(path);
  var editor = CodeMirror.fromTextArea(editBox, {
    lineNumbers: true,
    mode: "text/x-sh"
  });
  editor.on("change", function () {
    editor.save();
  });
};

var saveDeployFile = function () {
  $.post('/deploys/edit', {
    path: $('#filePath').text(),
    text: $('#editBox').val()
  }, function () {
    $("#saved").show().delay(2000).fadeOut();
  });
};

var editMonitor = function (path)
{
  $('.CodeMirror').each(function (i, el) {
    el.parentNode.removeChild(el);
  });
  $.ajax({url:"/monitors/get_file_contents/" + path, cache: false, async: false, success: function (result) {
    $('#editBox').val(result);
  }});
  $('#filePath').html(path);
  var editor = CodeMirror.fromTextArea(editBox, {
    lineNumbers: true,
    mode: "text/x-sh"
  });
  editor.on("change", function () {
    editor.save();
  });
};

var saveMonitorFile = function () {
  $.post('/monitors/edit', {
    path: $('#filePath').text(),
    text: $('#editBox').val()
  }, function () {
    $("#saved").show().delay(2000).fadeOut();
  });
};

var passDataToModal = function (data, modal_id) {
  $(".modal-body #dataInput").text(data);
  $(".modal-body #dataInput").val(data);
  $(".modal-footer #dataInput").val(data);
  $(modal_id).modal('show');
};

var editTeam = function (name) {
  $.get('/team/edit/' + name, function (data) {
    $('#teameditor').html(data);
    $('#editTeam').modal('show');
  });
};

var getTaskNotifications = function (task_id, refreshing) {
  if (typeof(refreshing)==='undefined') refreshing = false;
  $.get('/notifications/bytask/' + task_id, function (data) {
    var accordions = [];
    $( ".accordion-body" ).each( function( index ) {
      if ($( this ).attr('id') !== "nocollapse"){
        accordions[index] = $( this ).attr('class');
      }
    });
    $('#taskNotifications').html(data);
    for (var index in accordions){
      $( ".accordion-body" ).eq(index).attr('class', accordions[index]);
    }
    if ( document.getElementById("finished") !== null ){
      if ( refreshing ){
        location.reload();
      }
    } else {
      var interval = setTimeout(function() { getTaskNotifications(task_id, true); }, 15000);
    }
  });
};

var reloadTasks = function (){
  $.get('/task/list', function (data) {
    var newDoc = $(data).contents();
    currlength = $('#active tr').length;
    if ( $('#active tr .dataTables_empty').length !== 0 ) {
      currlength = 0;
    }
    if ( currlength !== newDoc.find("#active tr").length ){
      location.reload();
    }
  });
};

var delTask = function (id) {
  $.get('/task/del/' + id, function (data) {
    location.reload();
  });
};

// TODO: Make the backend return a json element so we can replace everything on the fly instead of simply readding elements
var addTeamMember = function (team) {
  var username = $('#selectAddUser').val();
  $.post('/team/add-member', {
    team: team,
    username: username
  }, function () {
    $('#teamMembers').append('<div class="input-append" id="' + username + '"><span class="add-on" style="width: 78px;">' + username + '</span><button class="btn" type="button" onclick="delTeamMember(\'' + team + '\', \'' + username + '\')"><i class="icon-minus"></i></button></div>');
    $('#selectAddUser').find('option[value="' + username + '"]').remove();
    // e.removeChild(e.options[e.selectedIndex]);
  });
};

var delTeamMember = function (team, username) {
  $.post('/team/del-member', {
    team: team,
    username: username
  }, function () {
    $('#' + username).remove();
    $('#selectAddUser').append('<option value="' + username + '">' + username + '</option>');
  });
};

var dismissNotification = function (msg_id) {
  $.post('/notification/dismiss', {
    msg_id: msg_id
  }, function () {

  });
};

var dismissMonitoringNotification = function (msg_id) {
  $.post('/notification/monitoring/dismiss', {
    msg_id: msg_id
  }, function () {
    $('#' + msg_id).remove();
  });
};

var acknowledgeMonitoringNotification = function (msg_id) {
  $.post('/notification/monitoring/acknowledge', {
    msg_id: msg_id
  }, function () {
    $('#' + msg_id).remove();
  });
};

var load_spinner = function () {
  $('body').append( '<div class="spinner-container"><div class="spinner"></div></div>' );
};
