// Standard callback functions which display the returnObject on the testpage and on the console

// [!] required in EFIPluginSimulator.js - callAll()
// [!] required for the function calls on the testpage

var CB = {

		result : "empty",

		standard : function(_me,_returnObject)
		{
			if(_returnObject.ACK == true)
			{
				CB.success(_me,_returnObject);
			}
			else{
				CB.fail(_me,_returnObject);
			}
		},

		// displays the returnObject on the testpage and on the console
		success : function(_me,_returnObject)
		{
			var result = _me + ":";
			var dataString = "";

			dataString = JSON.stringify(_returnObject.data);

			result +=dataString;
			CB.result = result;

			if(EFIHelper.testMode)
			{
				console.log(result);
				//console.log(CB.result);
				CB.writeToOutputField(result);
			}
		},

		// displays the error message on the testpage and on the console
		fail : function(_me,_returnObject)
		{
			// Fehler zeigen
			var result = _me + ":";
			var dataString = "";

			dataString += "ERROR: ";
			dataString += _returnObject.DETAIL;
			dataString += "";

			result +=dataString;
			CB.result = result;

			if(EFIHelper.testMode)
			{
				console.log(result);
				CB.writeToOutputField(result);
			}
		},

		// displays a String on the testpage
		writeToOutputField : function(text)
		{
			var outputField = document.getElementById("output");
			outputField.innerHTML = text;

			CB.showQueue();
			CB.showCar();
		},

		// diaplays the parameters of the EFIPluginSimulatorCar on the testpage
		showCar : function()
		{
			var carString = JSON.stringify(car);
			var objectLength = carString.length;

			var current = "";
			var newString = "";

			for(var i=0;i< objectLength;i++)
			{
				current = carString[i];

				if(current == ",")
					{
					newString += ",<br />";
					}
				else if(current == "\"")
				{

				}
				else if(current == ":")
				{
					newString += ": ";
				}
				else if(current == "{")
					{

					}
				else if(current == "}")
				{

				}
				else{
					newString += current;
				}
			}


			var outputField = document.getElementById("car");
			outputField.innerHTML = newString;
		},

		// displays the callback queue on the testpage
		showQueue : function()
		{
			var queueString = "";

			for(var i in EFIHelper.queue.callbacks)
				{
					queueString += (parseInt(i)+1) + ".) " + EFIHelper.queue.callbacks[i] + "<br />";
				}


			var outputField = document.getElementById("queue");
			outputField.innerHTML = queueString;
		},


		setTestCase : function(_testNumber)
		{
			if(_testNumber < 0 | _testNumber > 3)
			{
				_testNumber = 0;
			}
			car.testCase = _testNumber;

			CB.showCar();
		},

		showQueueDelay : function()
		{
			var outputField = document.getElementById("queueDelay");
			outputField.innerHTML = "Queue delay: " + EFIHelper.queue.delay + " ms";
		},

		setQueueDelay : function(_delay)
		{
			if(_delay >= 0)
			{
				EFIHelper.queue.delay = _delay;
			}
			CB.showQueueDelay();
		},


		//##########################################################################################
		// CALLBACK FUNCTIONS
		//##########################################################################################

		//==========================================================================================
		// : startTeleserviceCall 4.1
		//==========================================================================================
		startTeleserviceCall : function(_rO)
		{
			var me = "startTeleserviceCall";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : setDestWGS84 4.2
		//==========================================================================================
		setDestWGS84 : function(_rO)
		{
			var me = "setDestWGS84";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getArrivalTime 4.3
		//==========================================================================================
		getArrivalTime : function(_rO)
		{
			var me = "getArrivalTime";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getAudioSource 4.4
		//==========================================================================================
		getAudioSource: function(_rO)
		{
			var me = "getAudioSource";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getCarSettings 4.5
		//==========================================================================================
		getCarSettings : function(_rO)
		{
			var me = "getCarSettings";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getCarStatus 4.6
		//==========================================================================================
		getCarStatus : function(_rO)
		{
			var me = "getCarStatus";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getCoDriver 4.7
		//==========================================================================================
		getCoDriver : function(_rO)
		{
			var me = "getCoDriver";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getCruisingRange 4.8
		//==========================================================================================
		getCruisingRange : function(_rO)
		{
			var me = "getCruisingRange";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getDestWGS84 4.9
		//==========================================================================================
		getDestWGS84 : function(_rO)
		{
			var me = "getDestWGS84";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getDistanceToDestination 4.10
		//==========================================================================================
		getDistanceToDestination : function(_rO)
		{
			var me = "getDistanceToDestination";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getDrivingDirection 4.11
		//==========================================================================================
		getDrivingDirection : function(_rO)
		{
			var me = "getDrivingDirection";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getFuelType 4.12
		//==========================================================================================
		getFuelType : function(_rO)
		{
			var me = "getFuelType";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getJourneyComputerData 4.13
		//==========================================================================================
		getJourneyComputerData : function(_rO)
		{
			var me = "getJourneyComputerData";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getKilometerStatus 4.14
		//==========================================================================================
		getKilometerStatus : function(_rO)
		{
			var me = "getKilometerStatus";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getPhoneStatus 4.15
		//==========================================================================================
		getPhoneStatus : function(_rO)
		{
			var me = "getPhoneStatus";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getPosAdr 4.16
		//==========================================================================================
		getPosAdr : function(_rO)
		{
			var me = "getPosAdr";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getPosWGS84 4.17
		//==========================================================================================
		getPosWGS84 : function(_rO)
		{
			var me = "getPosWGS84";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getRadioStation 4.18
		//==========================================================================================
		getRadioStation : function(_rO)
		{
			var me = "getRadioStation";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getTVStation 4.19
		//==========================================================================================
		getTVStation : function(_rO)
		{
			var me = "getTVStation";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getUserAgent 4.20
		//==========================================================================================
		getUserAgent : function(_rO)
		{
			var me = "getUserAgent";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : getVersion 4.21
		//==========================================================================================
		getVersion : function(_rO)
		{
			var me = "getVersion";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : goHome 4.22
		//==========================================================================================
		goHome : function(_rO)
		{
			var me = "goHome";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : makeVoiceCall 4.23
		//==========================================================================================
		makeVoiceCall : function(_rO)
		{
			var me = "makeVoiceCall";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// :  4.24 NAVIS –to be clarified
		//==========================================================================================
		// TODO

		//==========================================================================================
		// :  4.25 PIA –to be clarified
		//==========================================================================================
		// TODO

		//==========================================================================================
		// : Restart 4.26
		// DEPRECATED
		//==========================================================================================
		Restart: function(_rO)
		{
			var me = "Restart";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : sendToAddress 4.27
		// TBD
		// TODO
		//==========================================================================================
		sendToAddress : function(_rO)
		{
			var me = "sendToAddress";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : setHome 4.28
		//==========================================================================================
		setHome : function(_rO)
		{
			var me = "setHome";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : setVINRN 4.29
		//==========================================================================================
		setVINRN : function(_rO)
		{
			var me = "setVINRN";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : startBIN 4.30
		//==========================================================================================
		startBIN : function(_rO)
		{
			var me = "startBIN";
			CB.standard(me,_rO);
		},

		//==========================================================================================
		// : 4.31 textToTTS nicht mehr unterstützt
		// TODO
		//==========================================================================================

		//==========================================================================================
		// : 4.31 textToTTSAndRedirect nicht mehr unterstützt
		// TODO
		//==========================================================================================

		//==========================================================================================
		// : 4.32 voice
		// TBD
		// TODO
		//==========================================================================================

		//==========================================================================================
		// : 4.33 wtai://wp/mc;
		// TODO
		//==========================================================================================

		//##########################################################################################
		// end of EFI-FUNCTIONS
		//##########################################################################################
};