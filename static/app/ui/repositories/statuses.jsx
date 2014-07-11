/** @jsx React.DOM */
define([
	"react",
	"jquery",
	"models/state",
	"mixins/pagestate",
	"mixins/immutable"],

	function(React,$,State,PageState,Immutable) {
		var RepositoryRef = React.createClass({
			mixins : [Immutable],

			getActionIcon : function(action){
				if (action.type === "normal")
					return <a key={action.key} className="action-link" title={action.title} href={this.props.links[action.link]} target="_blank"><i className={action.icon}></i></a>;
				else
					return <a key={action.key} className="action-link" title={action.title} onClick={this.performAction} data-link={action.link}><i className={action.icon}></i></a>;
			},

			performAction : function(e){
				var link = $(e.currentTarget).data("link");

				State.performRepositoryRefAction(this.props.repoid,this.props.key,link);
			},

			render : function(){
				var actions = this.props.actions || [];

				return <div key={this.props.type+"-"+this.props.name}>
					{this.props.type}&nbsp;
					{this.props.name}&nbsp;
					<span className={"label label-"+this.props.status}>{this.props.status_message}</span>
					{ actions.map(this.getActionIcon) }
				</div>;
			}
		});

		var RepositoryStatus = React.createClass({
			mixins: [ Immutable ],

			componentDidMount : function(){
				State.performRepositoryAction(this.props.key,"status");
			},

			getActionIcon : function(action){
				if (action.type === "normal")
					return <span key={action.key}><a className="btn btn-link" title={action.title} href={this.props[action.link]} target="_blank"><i className={action.icon}></i></a></span>;
				else
					return <span key={action.key}><a className="btn btn-link" title={action.title} onClick={this.performAction} data-link={action.link}><i className={action.icon}></i></a></span>;
			},

			performAction : function(e){
				var link = $(e.currentTarget).data("link");

				State.performRepositoryAction(this.props.key,link);
			},

			render : function() {
				var refs = this.props.refs || [];
				var actions = this.props.actions || [];
				var info = [];

				refs = refs.map(function(r){
					r.repoid = this.props.key;
					return r;
				}.bind(this));

				if (this.props.loading)
					info = <span>Loading ...</span>;
				else if (this.props.status)
					info = <div>
						<div>Push webhook: {this.props.links.pushhook}</div>
						<span>
							repo&nbsp;
							<span className={"label label-"+this.props.status}>
								{this.props.status_message}
							</span>&nbsp;
							<span>
								{ actions.map(this.getActionIcon) }
							</span>
						</span>
						<div>{ refs.map(RepositoryRef) }</div>
					</div>;

				return <div className="row repo" key={this.props.id}>
					<div className="col-md-4 name">{ this.props.label }</div>
					<div className="col-md-8 status">{info}</div>
				</div>;
			}
		});

		var EmptyList = React.createClass({
			render : function(){
				return <div className="row no-rows"><div className="col-md-12">No repositories</div></div>;
			}
		});

		var RepositoryStatuses = React.createClass({
			mixins: [ PageState, Immutable ],

			render : function() {
				return <div>
					<div className="row heading">
						<div className="col-md-4 name">Repository</div>
						<div className="col-md-8 status">Status</div>
					</div>
					{ this.props.repositories.length
						? this.props.repositories.map(RepositoryStatus)
						: EmptyList()
					}
				</div>;
			}
		});

		return RepositoryStatuses;
	}
);