define(["backbone","react","jquery","underscore"], function(Backbone,React,$,_) {
	var Repositories = {
		getRepository : function(repo){
			return this.get("state").repositories.filter(function(r){
				return r.key === repo;
			}).pop();
		},
		updateRepository : function(repo,updates){
			var index = -1, state = this.get("state"), change = { repositories:{} };

			for (var i=0; i<state.repositories.length; i++){
				if (state.repositories[i].key === repo){
					index = i;
				}
			}
			change.repositories[index] = { $merge:updates };

			return change;
		},
		performRepositoryAction : function(repo,action){
			var repository = this.getRepository(repo);

			if (repository.links[action] === undefined)
				throw new Error("Repository doesn't have link ["+action+"]");

			this.updateState(this.updateRepository(repo,{ loading:true }));

			this.ajaxJSON({
				url : repository.links[action],
				dataType : "json",
				callback : function(error,response){
					if (response)
						this.updateState(
							this.updateRepository(repo,{ loading:null }),
							this.updateRepository(repo,response.repository)
						);
					else
						this.updateState(
							this.updateRepository(repo,{ loading:null })
						);
				}.bind(this)
			});
		},
		performRepositoryRefAction : function(repo,ref,action){
			var repository = this.getRepository(repo), thisref = {};

			for (var i=0; i<repository.refs.length; i++){
				if (repository.refs[i].key === ref)
					thisref = repository.refs[i];
			}

			if (thisref === undefined && thisref.links[action] === undefined)
				throw new Error("Reference doesn't have link ["+action+"]");

			this.updateState(this.updateRepository(repo,{ loading:true }));

			this.ajaxJSON({
				url : thisref.links[action],
				dataType : "json",
				callback : function(error,response){
					if (response)
						this.updateState(
							this.updateRepository(repo,{ loading:null }),
							this.updateRepository(repo,response.repository)
						);
					else
						this.updateState(
							this.updateRepository(repo,{ loading:null })
						);
				}.bind(this)
			});
		}
	};

	var Tasks = {
		getTask : function(task){
			return this.get("state").tasks.filter(function(r){
				return r.key === task;
			}).pop();
		},
		updateTask : function(task,updates){
			var index = -1, state = this.get("state"), change = { tasks:{} };

			for (var i=0; i<state.tasks.length; i++){
				if (state.tasks[i].key === task){
					index = i;
				}
			}

			change.tasks[index] = { $merge:updates };

			return change;
		},
		performTaskAction : function(task,action,cb){
			var thistask = {}, generallinks = {}, updates = [];

			if (task){
				thistask = this.getTask(task)

				if (thistask.links[action] === undefined)
					return;

				this.updateState(this.updateTask(task,{ loading:true }));

				this.ajaxJSON({
					url : thistask.links[action],
					dataType : "json",
					callback : function(error,response){
						if (response && response.tasks)
							this.updateState(
								this.mergeState(response)
							);
						else if (response && response.tasks)
							this.updateState(
								this.updateTask(task,{ loading:null }),
								this.updateTask(task,response.task)
							);
						else
							this.updateState(
								this.updateTask(task,{ loading:null })
							);
						if (cb)
							cb();
					}.bind(this)
				});
			}
			else{
				generallinks = this.get("state").tasklinks || {};

				if (generallinks[action] === undefined)
					return;

				var tasks = this.get("state").tasks;

				this.ajaxJSON({
					url : generallinks[action],
					dataType : "json",
					callback : function(error,response){
						if (response)
							this.updateState(this.mergeState(response));
						if (cb)
							cb();
					}.bind(this)
				});
			}
		}
	};

	var Messages = {
		getMessageIndex : function(id){
			var state = this.get("state"), index = -1;

			for (var i=0; i<state.messages.length; i++){
				if (state.messages[i].id === id)
					index = i;
			}

			return index;
		},

  		addMessage : function(message,status,details){
  			status = status || "info";
  			return { messages : { $push:[{ status:status, message:message, details:details, key:_.uniqueId("message") }] } };
  		},

  		removeMessage : function(index){
  			return { messages : { $splice : [ [index,1] ] } };
  		},

  		closeMessage : function(id){
  			var index = this.getMessageIndex(id);

  			if (index > -1)
	  			this.updateState(this.removeMessage(index));
  		},

  		setError : function(err){
  			var message = "";
  			var details = undefined;

  			if (err instanceof Error){
  				message = err.toString();
  				details = err.stack;
  			}
  			else if (err.Message !== undefined){
  				message = err.Message;
  				details = err;
  			}
  			else{
  				message = err.toString();
  			}

  			this.updateState(this.addMessage(message,"danger",details));
  		}
	};

	var State = Backbone.Model.extend(_.extend(Repositories,Tasks,Messages,{
  		updateState : function(){
  			var state = this.get("state");

  			for (var i=0; i<arguments.length; i++){
  				state = React.addons.update(state,arguments[i]);
  			}

  			this.set("state",state);
  		},

  		mergeState : function(updates){
			var state = this.get("state"), change = {};

			for (var k in updates){
				switch (k){
					case "links":
						change[k] = { $merge : updates[k] };
						delete updates[k];
						break;
					case "messages":
						change[k] = { $push : updates[k] };
						delete updates[k];
						break;
					default:
						change[k] = { $set : updates[k] };
						break;
				}
			}

			return change;
  		},

  		ajaxJSON : function(opts){
  			opts.success = function(response){
  				if (typeof(response.Message)==="string"){
  					this.setError(response);
  					if (opts.callback) opts.callback(response);
  				}
  				else {
  					if (response.messages){
  						this.updateState({ messages : { $push:response.messages } });
  						delete response.messages;
  					}
  					if (opts.callback) opts.callback(null,response);
  				}
  			}.bind(this);

  			$.ajax(opts);
  		}
	}));

	if (!(window.state instanceof Backbone.Model)){
		window.state.messages = window.state.messages || [];
		window.state = new State({ state:window.state });
	}

	$( document ).ajaxError(function( event, jqxhr, settings, exception ) {
		window.state.setError($.parseJSON(jqxhr.responseText));
	});

	return window.state;
});