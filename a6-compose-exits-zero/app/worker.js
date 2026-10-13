console.log('worker starting');
setInterval(() => console.log('heartbeat ' + new Date().toISOString()), 2000);
