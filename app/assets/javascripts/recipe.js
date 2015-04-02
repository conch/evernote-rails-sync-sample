var readyHandler = function() {
  $("#save").click(function() {
    $("#success, #fail, .noteLink").hide();
    $("#saving").show();
    var x = new XMLHttpRequest();
    x.open("get", location.href + "/save");
    x.onreadystatechange = function() {
      if (this.readyState === 4) {
        $("#saving").hide();
        if (this.status === 200) {
          var successElt = $("#success");
          successElt.show();
          var noteLink = document.createElement("a");
          noteLink.textContent = this.response;
          noteLink.target = "_blank";
          noteLink.href = this.response;
          noteLink.className = "noteLink";
          successElt[0].parentNode.insertBefore(noteLink, successElt[0].nextElementSibling);
        } else {
          $("#fail").show();
        }
      }
    };
    x.send();
  });
};

$(document).ready(readyHandler);
$(document).on('page:load', readyHandler); // for rails 4 turbolinks
