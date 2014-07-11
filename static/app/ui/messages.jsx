/** @jsx React.DOM */
define([
	"react",
	"models/state",
	"mixins/pagestate",
	"mixins/immutable"],

	function(React,State,PageState,Immutable) {
		var Message = React.createClass({
			mixins: [ Immutable ],

			jsonHighlight : function(json) {
				if (typeof json != 'string')
					json = JSON.stringify(json, null, 4);

				json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
				
				return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
					var cls = 'number';
					if (/^"/.test(match)) {
						if (/:$/.test(match)) {
							cls = 'key';
						} else {
							cls = 'string';
						}
					} else if (/true|false/.test(match)) {
						cls = 'boolean';
					} else if (/null/.test(match)) {
						cls = 'null';
					}
					return '<span class="' + cls + '">' + match + '</span>';
				});
			},

			getInitialState : function(){
				return {
					hideDetails : true
				};
			},

			closeMessage : function(){
				State.closeMessage(this.props.id);
			},

			toggleDetails : function(){
				this.setState({ hideDetails:!this.state.hideDetails });
			},

			render : function() {
				return <div className={"alert alert-"+this.props.status+" alert-dismissable"}>
					<span className="pull-right">
						<a className="close" aria-hidden="true" onClick={this.closeMessage}><i className="fa fa-times"></i></a>
						{ this.props.details
							? <a className="more-info" onClick={this.toggleDetails}><i className="fa fa-info"></i></a>
							: []
						}
					</span>
					{this.props.message}
					{ !this.state.hideDetails && this.props.details
						? <pre className="details json" dangerouslySetInnerHTML={{__html: this.jsonHighlight(this.props.details)}} />
						: []
					}
				</div>
			}
		});

		var Messages = React.createClass({
			mixins: [ PageState, Immutable ],

			render : function() {
				return <div>{this.props.messages.map(Message)}</div>;
			}
		});

		return Messages;
	}
);