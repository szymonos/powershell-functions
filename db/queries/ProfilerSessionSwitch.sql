/* Włączenie sesji Extended Events używanej przez Profilera */
alter event session ADS_Standard_Azure on database state = start;

/* Wyłączenie sesji Extended Events używanej przez Profilera */
alter event session ADS_Standard_Azure on database state = stop;
