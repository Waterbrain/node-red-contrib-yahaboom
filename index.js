const Yahaboom = require('node-red-contrib-oled');
var exec = require('child_process').exec;

exec('sudo systemctl status RGB_Cooling_HAT_C_1 | grep " Active: active (running)" | wc -l',
    function (error, stdout, stderr) {
        //console.log('stdout: ' + stdout);
        //console.log('stderr: ' + stderr);
        if (stdout != 0) {
             console.error('RGB_Cooling_HAT_C_1 service running. node-red-contrib-oled may be working wrong. please stop it.');
        }
    });
exec('sudo systemctl status RGB_Cooling_HAT_C | grep " Active: active (running)" | wc -l',
    function (error, stdout, stderr) {
        //console.log('stdout: ' + stdout);
        //console.log('stderr: ' + stderr);
        if (stdout != 0) {
             console.error('RGB_Cooling_HAT_C service running. node-red-contrib-oled may be working wrong. please stop it.'); 
        }
    });

exec('sudo systemctl status RGB_Cooling_HAT | grep " Active: active (running)" | wc -l',
    function (error, stdout, stderr) {
        //console.log('stdout: ' + stdout);
        //console.log('stderr: ' + stderr);
        if (stdout != 0) {
             console.error('RGB_Cooling_HAT service running. node-red-contrib-oled may be working wrong. please stop it.');
        }
    });

exec('sudo ps -ef | grep temp_control  | wc -l',
    function (error, stdout, stderr) {
        //console.log('stdout: ' + stdout);
        //console.log('stderr: ' + stderr);
        if (stdout != 1) {
             console.error('RGB_Cooling_HAT running. node-red-contrib-oled may be working wrong. please stop it.');
        }
    });

	'---------------------------------- Registration ----------------------------------'
	RED.nodes.registerType('Clear', Yahaboom('clearDisplay'))
	RED.nodes.registerType('Dimmed', Yahaboom('dimDisplay'))
	RED.nodes.registerType('Invertion', Yahaboom('invertDisplay'))
	RED.nodes.registerType('Turn-off', Yahaboom('turnOffDisplay'))
	RED.nodes.registerType('Turn-on', Yahaboom('turnOnDisplay'))
	RED.nodes.registerType('oled-config', Yahaboom('OledConfig'))
	RED.nodes.registerType('Pixel', Yahaboom('Pixel'))
	RED.nodes.registerType('Line', Yahaboom('Line'))
	RED.nodes.registerType('FillRectangle', Yahaboom('FillRectangle'))
	RED.nodes.registerType('String', Yahaboom('String'))
	RED.nodes.registerType('Scroll', Yahaboom('Scroll'))
	RED.nodes.registerType('Battery', Yahaboom('Battery'))
	RED.nodes.registerType('Wifi', Yahaboom('Wifi'))
	RED.nodes.registerType('Bluetooth', Yahaboom('Bluetooth'))
	RED.nodes.registerType('Image', Yahaboom('Image'))