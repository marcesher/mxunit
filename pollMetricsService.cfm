<cfscript>
thisTask = application.completionService.poll();
while(  NOT isNull( thisTask ) ){

	try
    {
    	result = thisTask.get();
    	writeDump(result);
    }
    catch(Any e)
    {
		writeDump(var=e, label="Error occurred on a Future.get() call");
    }


	thisTask = application.completionService.poll();
}
 	 
</cfscript>