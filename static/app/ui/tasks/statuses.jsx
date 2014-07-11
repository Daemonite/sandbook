/** @jsx React.DOM */
define([
	"react",
	"jquery",
	"models/state",
	"mixins/pagestate",
	"mixins/immutable",
	"pietimer"],

	function(React,$,State,PageState,Immutable) {

		var TaskStatus = React.createClass({
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

			toggleDetails : function(){
				this.setState({ hideDetails:!this.state.hideDetails });
			},

			getActionIcon : function(action){
				return <a key={action.key} style={ {cursor:"pointer"} } onClick={this.performAction} data-link={action.link}><i className={action.icon}></i></a>;
			},

			performAction : function(e){
				var link = $(e.currentTarget).data("link");

				State.performTaskAction(this.props.key,link);
			},

			render : function() {
				var actions = this.props.actions || [];
				var info = [];
				var args = [];

				if (this.props.loading){
					info = <span>Loading ...</span>;
					actions = [];
				}
				else if (this.props.status && this.props.status.indexOf(":") > -1){
					info = "Processing: " + this.props.status.split(":")[1];
					actions = actions.map(this.getActionIcon);
				}
				else if (this.props.status){
					info = this.props.status;
					actions = actions.map(this.getActionIcon);
				}

				for (var k in this.props["arguments"])
					args.push(k);
				args = args.join(", ");

				return <tr>
					<td>{this.props.id}</td>
					<td>{this.props.component}</td>
					<td>{this.props.method}</td>
					<td>{args} <a className="more-info" onClick={this.toggleDetails}><i className="fa fa-info"></i></a>
						{ !this.state.hideDetails
							? <pre className="arguments json" dangerouslySetInnerHTML={{__html: this.jsonHighlight(this.props["arguments"])}} />
							: []
						}
					</td>
					<td>{info}</td>
					<td>{actions}</td>
				</tr>;
			}
		});

		var EmptyList = React.createClass({
			render : function(){
				return <tr><td colSpan="6">No tasks</td></tr>;
			}
		});

		var TaskStatuses = React.createClass({
			mixins: [ PageState, Immutable ],

			componentDidMount : function(){
			    $('#timer').pietimer({
			        timerSeconds: 3,
			        color: '#000',
			        fill: true,
			        showPercentage: false,
			        callback: function() {
			        	$('#timer').pietimer('reset');
			            State.performTaskAction(null,"refreshalltasks",function(){
			            	$('#timer').pietimer('start');
			            });
			        }
			    }).hover(function(){
			    	var $this = $('#timer'), state = $this.data('pietimer');
			    	state.color = '#666';
			    	$this.data('pietimer',state);
			    },function(){
			    	var $this = $('#timer'), state = $this.data('pietimer');
			    	state.color = '#000';
			    	$this.data('pietimer',state);
			    }).on("mousedown",this.toggleTimer);
			},

			componentWillUnmount : function(){
				$("#timer").pietimer("reset");
			},

			getInitialState : function(){
				return {
					refreshTimer : true
				};
			},

			getActionIcon : function(action){
				return <button key={action.key} className="btn btn-default" onClick={this.performAction} data-link={action.link}><i className={action.icon}></i> {action.title}</button>;
			},

			performAction : function(e){
				var link = $(e.currentTarget).data("link");

				State.performTaskAction(null,link);
			},

			toggleTimer : function(e){
				if (this.state.refreshTimer){
					$('#timer').pietimer("stop");
					this.setState({ refreshTimer:false });
				}
				else {
					$('#timer').pietimer("start");
					this.setState({ refreshTimer:true });
				}

				e.stopPropagation();
			},

			render : function() {
				var actions = this.props.taskactions || [];

				return <div className="row">
					<div className="col-md-12">
						<div className="btn-group">{actions.map(this.getActionIcon)}<div id="timer"></div></div>
						<table className="table table-striped">
							<thead>
								<tr>
									<th>ID</th>
									<th>Component</th>
									<th>Method</th>
									<th>Arguments</th>
									<th>Status</th>
									<th></th>
								</tr>
							</thead>
							<tbody>
								{ this.props.tasks.length
									? this.props.tasks.map(TaskStatus)
									: <EmptyList />
								}
							</tbody>
						</table>
					</div>
				</div>;
			}
		});

		return TaskStatuses;
	}
);