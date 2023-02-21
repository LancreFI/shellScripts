Write-Host "This script renames files to ddmmyyhhmmss.extension"

#Get the path for the files to be renamed
$filepath = Read-Host -Prompt 'Input the path for the files'

#Add the possibly missing slash to the end of the path
if(!$filepath.EndsWith('\'))
{
    $filepath = $filepath+'\'
}

#If the path is non-existing
While(!(Test-Path $filepath))
{
	Write-Host "The path $filepath doesn't exist!"
	$filepath = Read-Host -Prompt 'Input the path for the files'
}

#Prompt for usage of EXIF Date taken -property
$select = 3
While($select -gt 1 -Or $select -lt 0)
{
    Write-Host 'Use the EXIF "Date taken" timestamp instead of last modification stamp if available?'
    Write-Host "If the date of the device used had the time settings wrong, don't use this!"
    $select = Read-Host -Prompt '1 = YES, 0 = NO'
}

#Get the filenames in the user selected path
$files = (Get-ChildItem -Path $filepath ).FullName

#Count the files
$arrlength = $files.Count

#Process file by file
for($i=0; $i -lt $arrlength; $i++)
{
    #Get the last modification date
	$fdatename = (Get-item $files[$i]).lastwritetime.ToString('ddMMyy_HHmmss')

    #Get the file extension (includes the .)
    $fextension = [System.IO.Path]::GetExtension($files[$i])
    
    #Get the exif stamp, if user has opted to use it
    $excepted = 0;
    if($select -eq 1)
    {
        #Note that the object reserves the file, so you need to dispose it later to be able to rename
        $exif = New-Object System.Drawing.Bitmap($files[$i])
        try
        {
            #Test for exif property "Date taken"
            $propVal = $exif.GetPropertyItem(36867).Value
        }
        #If the property does not exist, catch the ArgumentException
        Catch [ArgumentException]
        {
            $excepted = 1;
        }
        Finally
        {
            #If the property exists
            if($excepted -eq 0)
            {
                #PropertyItem 36867 = Date taken
                $bytearr = $exif.GetPropertyItem(36867).Value
                #Convert the value from byte array, to string
                $fpropVal = [System.Text.Encoding]::ASCII.GetString($bytearr)
                #Parse the date from the exact form of yyyy:MM:dd HH:mm:ss and then convert it to string in format of ddMMyy_HHmmss
                $fdatename = [datetime]::ParseExact($fpropVal,"yyyy:MM:dd HH:mm:ss`0",$Null).ToString('ddMMyy_HHmmss')
            }
        }
        #What was commented on row 47
        $exif.Dispose()
    }

    #Make sure the filename isn't in use already
    $counter=0
    while(Test-Path $filepath$fdatename$fextension)
    {
        #First time around just add the _0 to filename
        if($counter -eq 0)
        {
            $fdatename = $fdatename+"_"+$counter
        }
        #Then increment the 0 upwards as long as needed
        else
        {
            $prevcounter = $counter-1
            $repl = "_"+$prevcounter+'$'
            $repwith = '_'+$counter
            $fdatename = $fdatename -replace $repl,$repwith
        }
        $counter++
    }
    #Set the final output path\file.ext
    $fdatename = $filepath+$fdatename+$fextension

    #Lastly rename the files with the ddMMyy_HHmmss.ext
	  Rename-Item $files[$i] $fdatename
}

Write-Host "Renamed $arrlength files"
