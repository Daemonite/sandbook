component {
	
	public any function init(fw){
		var q = "";

		variables.fw = arguments.fw;
		this.processes = {};

		// initialize db
		variables.dsn = variables.fw.getADConfig("db");

		q = new Query();
		q.setDatasource(variables.dsn);
		q.setSQL("select * from queue");
		try{
			q.execute();
		}
		catch(any e){
			// failure means the table hasn't been created
			q = new Query();
			q.setDatasource(variables.dsn);
			q.setSQL("
				CREATE TABLE `queue` (
				  `id` INT NOT NULL AUTO_INCREMENT,
				  `component` VARCHAR(255) NOT NULL,
				  `method` VARCHAR(45) NOT NULL,
				  `arguments` TEXT NOT NULL,
				  `locks` VARCHAR(255) NULL,
				  `status` VARCHAR(255) NOT NULL,
				  PRIMARY KEY (`id`));
			");
			q.execute();
		}

		return this;
	}

	public numeric function getMergerTask(required string mergingLocks){
		var q = new Query();
		var sql = "SELECT id, locks, status FROM `queue` WHERE status='queued' AND (1=0 ";
		var i = 0;
		var aLocks = [];
		var qResult = "";

		if (arguments.mergingLocks eq "")
			return 0; 

		aLocks = listtoarray(arguments.mergingLocks);

		for (i=1; i<=arraylen(aLocks); i++)
			sql &= "OR locks LIKE '%,#aLocks[i]#,%' ";

		sql &= ") ORDER BY id desc";

		q.setDatasource(variables.dsn);
		q.setSQL(sql);

		qResult = q.execute().getResult();

		if (qResult.recordcount)
			return qResult.id[1];
		else
			return 0;
	}

	public boolean function isTaskBlocked(required struct task){
		var q = new Query();
		var sql = "SELECT id FROM `queue` ";
		var i = 0;
		var aLocks = listtoarray(arguments.task.locks);

		for (i=1; i<=arraylen(aLocks); i++)
			sql &= "(id<:id and locks like '%,#aLocks[i]#,%') ";

		q.addParam(name="id", value=arguments.task.id, type="cf_sql_numeric");
		q.setDatasource(variables.dsn);
		q.setSQL(sql);

		return q.execute().getResult().recordcount > 0;
	}

	public numeric function queueTask(required string component, required string method, required any args, required string locks, string status="queued", string mergingLocks=""){
		var qResult = structnew();
		var q = new Query();
		var merger = getMergerTask(arguments.mergingLocks);

		if (merger){
			q.setDatasource(variables.dsn);
			q.setSQL("
				UPDATE `queue`
				SET
				  `component`=:component,
				  `method`=:method,
				  `arguments`=:arguments,
				  `locks`=:locks,
				  `status`=:status
				WHERE
				  id=:id;
			");
			q.addParam(name="component", value=arguments.component, type="cf_sql_varchar");
			q.addParam(name="method", value=arguments.method, type="cf_sql_varchar");
			q.addParam(name="arguments", value=serializeJSON(arguments.args), type="cf_sql_varchar");
			q.addParam(name="locks", value="," & arguments.locks & ",", type="cf_sql_varchar");
			q.addParam(name="status", value=arguments.status, type="cf_sql_varchar");
			q.addParam(name="id", value=merger, type="cf_sql_numeric");
			q.execute();
			return merger;
		}
		else {
			q.setDatasource(variables.dsn);
			q.setSQL("
				INSERT INTO `queue` (
				  `component`,
				  `method`,
				  `arguments`,
				  `locks`,
				  `status`)
				VALUES (
				  :component,
				  :method,
				  :arguments,
				  :locks,
				  :status);
				SELECT LAST_INSERT_ID() as newID;
			");
			q.addParam(name="component", value=arguments.component, type="cf_sql_varchar");
			q.addParam(name="method", value=arguments.method, type="cf_sql_varchar");
			q.addParam(name="arguments", value=serializeJSON(arguments.args), type="cf_sql_varchar");
			q.addParam(name="locks", value="," & arguments.locks & ",", type="cf_sql_varchar");
			q.addParam(name="status", value=arguments.status, type="cf_sql_varchar");
			qResult = q.execute().getResult();
			return qResult.newID;
		}
	}

	public void function updateTaskStatus(required numeric id, required  string processid, required string status){
		var q = new Query();
		
		q.setDatasource(variables.dsn);
		q.setSQL("
			UPDATE `queue`
			SET
			  `status`=:newstatus
			WHERE
			  id=:id
		");
		q.addParam(name="newstatus", value="processing@#arguments.processid#:#arguments.status#", type="cf_sql_varchar");
		q.addParam(name="id", value=arguments.id, type="cf_sql_numeric");
		q.execute();
	}

	public string function getCurrentLocks(){
		var q = new Query();
		var i = 0;
		var j = 0;
		var qResult = "";
		var locks = "";

		q.setDatasource(variables.dsn);
		q.setSQL("
			SELECT `locks`
			FROM `queue`
			WHERE `status` like 'processing@%';
		");
		qResult = q.execute().getResult();
		
		for (i=1; i<=qResult.recordcount; i++){
			for (j=1; j<=listlen(qResult.locks[i]); j++){
				if (not listfindnocase(locks,listgetat(qResult.locks[i],j)))
					locks = listappend(locks, listgetat(qResult.locks[i],j));
			}
		}

		return locks;
	}

	public struct function getTask(required numeric id){
		var q = new Query();
		var i = 0;
		var qResult = "";
		var stResult = structnew();

		q.setDatasource(variables.dsn);
		q.setSQL("
			SELECT *
			FROM `queue`
			WHERE id=:id
		");
		q.addParam(name="id", value=arguments.id, type="cf_sql_numeric");
		qResult = q.execute().getResult();
		
		if (qResult.recordcount){
			for (i=1; i<listlen(qResult.columnlist); i++){
				stResult[listgetat(qResult.columnlist,i)] = qResult[listgetat(qResult.columnlist,i)][1];
			}
		}

		return stResult;
	}

	public struct function claimTask(required string processid){
		var locks = getCurrentLocks();
		var q = new Query();
		var sql = "";
		var i = 0;
		var qResult = "";
		var stResult = structnew();

		q.setDatasource(variables.dsn);
		sql = "
			UPDATE `queue`
			SET status=:newstatus
			WHERE status='queued'
		";

		for (i=1; i<=listlen(locks); i++){
			sql &= " AND q.locks not like :lock#i#";
			q.addParam(name="lock#i#", value='%,#listgetat(locks,i)#,%', type="cf_sql_varchar");
		}

		sql &= " ORDER BY id asc LIMIT 1;"
		sql &= " SELECT * FROM `queue` WHERE status=:newstatus;"

		q.setSQL(sql);
		q.addParam(name="newstatus", value='processing@#arguments.processid#:claimed', type="cf_sql_varchar");
		qResult = q.execute().getResult();
		
		if (qResult.recordcount){
			for (i=1; i<listlen(qResult.columnlist); i++){
				stResult[listgetat(qResult.columnlist,i)] = qResult[listgetat(qResult.columnlist,i)][1];
			}
		}

		return stResult;
	}

	public void function closeTask(required numeric id){
		var q = new Query();

		q.setDatasource(variables.dsn);
		q.setSQL("
			DELETE FROM `queue`
			WHERE id=:id
		");
		q.addParam(name="id", value=arguments.id, type="cf_sql_numeric");
		q.execute();
	}

	public string function runTasks(){
		var processid = createuuid();

		if (variables.fw.getADConfig("max_threads",1) > structcount(this.processes)){
			this.processes[processid] = now();

			setting requesttimeout="10000";

			thread name="#processid#" action="run" processid="#processid#" queue="#this#" {
				thread.processid = attributes.processid;

				try{
					task = {};
					task = attributes.queue.claimTask(attributes.processid);
					thread.task = task;

					while(structkeyexists(task,"id")){
						attributes.queue.processes[attributes.processid] = now();
						args = deserializeJSON(task["arguments"]);
						try{
							if (structkeyexists(application.services,task.component))
								application.services[task.component][task.method](argumentCollection=args);
							else
								createobject("component",task.component)[task.method](argumentCollection=args);
						}
						catch(any e){
							writeLog(file="queue",text='{ "error":#serializeJSON(e)#, "task":#serializeJSON(task)# }');
						}
						finally{
							attributes.queue.closeTask(task.id);
						}

						task = {};
						task = attributes.queue.claimTask(attributes.processid);
						thread.task = task;
					}
				}
				catch(any e){
					writeLog(file="queue",text='{ "error":#serializeJSON(e)#, "task":#serializeJSON(task)# }');
					rethrow;
				}
				finally{
					structdelete(attributes.queue.processes,attributes.processid);
				}
			}

			return processid;
		}

		return "";
	}

	public query function getStatus(){
		var q = new Query();

		q.setDatasource(variables.dsn);
		q.setSQL("
			SELECT id, component, method, arguments, status
			FROM `queue`
			ORDER BY id asc
		");

		return q.execute().getResult();
	}

	public array function queryToArray(required query q){
		var i = 0;
		var j = 0;
		var st = {};
		var aResult = [];
		var cols = listtoarray(arguments.q.columnlist)

		for (var i=1; i<=arguments.q.recordcount; i++){
			st = {};

			for (var j=1; j<=arraylen(cols); j++){
				st[lcase(cols[j])] = arguments.q[cols[j]][i];
			}

			arrayappend(aResult,st);
		}

		return aResult;
	}

}