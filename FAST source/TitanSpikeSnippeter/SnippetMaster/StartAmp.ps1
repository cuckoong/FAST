﻿param($hostname,$outpath,$numsamples,$nchans)
if (!$outpath) {
	echo "OutPath is necessary"
}
else {	
	if (!$numsamples) {
		echo "numsamples is necessary"
	}
	else {
		if (!$hostname) {
			echo "hostname is necessary"
		}
		else {
			$workerendpoint="tcp://192.168.0.201:5000"
			$serverendpoint="tcp://*:5000"
			$datafile="$outpath/Spikes"
			$outfile="$outpath/SpikeAmps"
			$cmd="C:\Titanic\Snippeter\SnippetMaster.exe"
			$prc="\\140.247.178.88\Rajesh\Ephys\ProcessRunnerService\ProcessRunnerClient\ProcessRunnerClient\bin\Release\ProcessRunnerClient.exe"
			New-NetFirewallRule -Name ZMQMapReduce -DisplayName ZMQMapReduce -Enabled True -Profile Any -Protocol TCP -LocalPort 5000 -Action Allow
			for ($j=1;$j -le 5;$j++) {
				for ($i=0;$i -lt 1;$i++) {
					iex "& '$prc' http:\\192.168.0.20$j`:8000 Administrator olabmstr!1 $cmd 'AmpWorker $hostname $datafile $nchans $outfile $workerendpoint $j-$i' C:\Titanic\Snippeter"
				}
			}
			$serverjob = Start-Job -ScriptBlock {
				param($cmd,$hostname,$serverendpoint,$numsamples)
				$sw = [Diagnostics.Stopwatch]::StartNew()
				iex "& '$cmd' AmpServer $hostname $numsamples $serverendpoint"
				$sw.Stop()
				$time = $sw.Elapsed.TotalSeconds
				echo "Took $time  seconds"
			} -ArgumentList $cmd,$hostname,$serverendpoint,$numsamples
			while ($serverjob.State -eq 'Running') {
				Start-Sleep -Milliseconds 100
				Receive-Job $serverjob
				foreach ($job in $jobs) {
					if ($job.State -ne 'Running') {
						Receive-Job $job
					}
				}
			}
			Remove-NetFireWallRule -Name ZMQMapReduce
		}
	}
}
