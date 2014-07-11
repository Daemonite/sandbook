require(["backbone","models/status"], function(Backbone,Repository) {
  return Backbone.Collection.extend({
  	model : Repository
  });
});