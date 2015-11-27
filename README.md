############################################################################################
#
#          Flex4grid LinkSmart LocalConnect ZWave integration layer
#
############################################################################################


INSTALLATION

- download and unzip LinkSmart LocalConnect (LSLC) . You will find it here. https://linksmart.eu/repo/content/repositories/public/eu/linksmart/lc/distribution/
Choose "flex4grid" distribution for your architecture.
Amd64 direct link: https://linksmart.eu/repo/content/repositories/public/eu/linksmart/lc/distribution/linux-amd64.flex4grid.deployable/0.2.0-SNAPSHOT/linux-amd64.flex4grid.deployable-0.2.0-20150923.164235-3-distribution.tar.gz
- overwrite the files in the LSLC distribution-folder with folder found in flex4grid/FIT/LSLC-ZWave
- For a household id registration "jq" and "uuid" command line tools need to be installed. 

CONFIGURATION

- configure the default (localhost) MQTT broker endpoing regardingly to your needs. You will find it in conf/device-gateway.json
- configure the Open ZWave environment (OZW) and the serial port used by the OZW controller. To do so edit the conf/ZWaveMultiplexer.conf
  The first line specifies the serial port of the OZW controller.  The second line points to your OZW environment directory
- The 3rd  line inside ZWaveMultiplexer.conf enables polling. By default polling is enabled. No changes are needed here.
- The 4th line of the ZWaveMultiplexer.conf specifies the interval between polls. The default value is 10000 ms. 

CLOUD REGISTRATION

- This step can be skipped if you don't want to register within the cloud. 
- In case you want to register and grab a new unique household_id from the cloud, call registerHousehold.sh first.
  No parameter means uuid will be generated . "MAC" means, the local MAC will be used for the registration.
  Example using MAC to generate the household ID: 
  "registerHousehold.sh MAC"
- You need to call the script only once

USAGE

- Start the ZWaveMultiplexer by calling "python ZWaveMultiplexer.py"
- Start LSLC binary gateway by calling "device-gateway" from the root distribution folder. 
- Browse the installed devices with the help of the Resource Catalog : http://localhost:8080/rc
- More LSLC documentation can be found here : https://linksmart.eu/redmine/projects/linksmart-local-connect/wiki


SMART PLUG CONTROL

Here some examples for rest calls to monitor and control the Smart Plug simulator.

SmartPlug Consumption
curl -i -H "Content-Type:application/json" http://localhost:8080/rest/Flex4GridDevice/SmartPlug_Consumption

SmartPlug Status
curl -i -H "Content-Type:application/json" http://localhost:8080/rest/Flex4GridDevice/SmartPlug_Status

SmartPlug Switch ON/OFF
curl -i -H "Content-Type:application/json" http://localhost:8080/rest/Flex4GridDevice/SmartPlug_Switch -X PUT -d "ON 6"
curl -i -H "Content-Type:application/json" http://localhost:8080/rest/Flex4GridDevice/SmartPlug_Switch -X PUT -d "OFF 6"

where 6 is the id of the ZWavePlug. SmartPlug status events reveal the id when the status is changed.
The id's are dynamicaly generated by the OZW layer.



TODO

* List of available SmartPlugs

