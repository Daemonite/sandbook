define(["models/state"], function(State) {
	return {
		addPageState : function(state){
			this._pagestate = state;
			state.on("change:state",function(model){
				this.setProps(model.get("state"));
			},this);
		},
		removePageState : function(){
			this._pagestate.off("change:state");
			delete this._pagestate;
		},

		componentWillMount : function(){
			this.addPageState(State)
		},
		componentWillUnmount : function(){
			this.removePageState();
		}
	};
});