<cfsetting showdebugoutput="true" >
<cfoutput>
<p>
	#application.metricsCollector.getWorkQueueSize()# parse tasks in the work queue. <br>

	#application.metricsCollector.getActiveTaskCount()# tasks actively running. <br>

#application.metricsCollector.getCompletionQueueSize()# parse tasks in the completion queue to be published</p>
</cfoutput>

<cfdump var="#application.metricsCollector.getCFMetricsCounters()#">