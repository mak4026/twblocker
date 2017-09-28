$(function() {
  $("#block-button").submit(function(){
    var ids = [];
    var block_list = $("#block_ids :checkbox:checked");
    block_list.each(function(){
      var id = $(this).next().find(".screen-name").text().trim();
      ids.push(id);
    });
    $(this).find("#block-target").val(JSON.stringify(ids));
  });
  $("#block_ids :checkbox").change(function(){
    $(this).parent().parent().toggleClass("disabled");
  });
});
