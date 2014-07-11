define([], function() {
	return {
		shouldComponentUpdate : function(nextProps, nextState){
			return nextProps !== this.props || nextState !== this.state;
		}
	};
});