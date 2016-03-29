;(function (){
var bodyLayout, outerCenterLayout, middleCenterLayout, middleWestLayout;
$(document).ready(function () {

  bodyLayout = $('body').layout({
    resizable: false,
    center__paneSelector: '.outer-center', // layout
    north__paneSelector: '.outer-north', // #header - pane for the header navigation bar
    north__size: 50,
    north__closable: false,
    north__slidable: false,
    west__paneSelector: '.outer-west', // #sources - pane for list of the input sources
    west__size: 150,
    south__paneSelector: '.outer-south', // #footer - pane for the status bar bottom
    south__size: 25
  });
  // for the pulldown menu by the header navigation bar
  bodyLayout.allowOverflow('north');

  outerCenterLayout = $('div.outer-center').layout({ 
    resizable: false,
    center__paneSelector: '.middle-center', // layout
    west__paneSelector: '.middle-west', // layout
    west__size: 150
  }); 
});
})();
