# remoteGatlingExecution
Shellscript to run open-source Gatling tool distributing the load through various load generators. 
It's my adaptation to the script posted on the [Gatling site](https://gatling.io/docs/current/cookbook/scaling_out/).

Please, pay attention to the following suggestions in order to have the script running properly:

- Ensure that you have ssh connection between your pc and the load generators with the users specified in the HOST variable.
- The Gatling installation should be in the same path in every load generator, and the path should be set in the GATLING_HOME variable.
- The users should have read and write permisions on ALL the involved directories, but specially in GATLING_REPORT_DIR and GATHER_REPORTS_DIR.
- Check that all the load generators could run gatling properly.
