component {
	
    public any function init(fw){
        variables.fw = arguments.fw;
        
        return this;
    }

	public void function sleepFor(period){
		var sofar = 0;

		while (sofar < period){
			application.services["tasks.services.queue"].updateTaskStatus(thread.task.id, thread.processid, "waited #sofar#s");
			sleep(1000);
			sofar += 1;
		}
	}

}