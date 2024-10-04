$scriptName = $MyInvocation.MyCommand.Name
# Check if two arguments are provided
if ($args.Count -ne 2) {
    Write-Host "Usage: $scriptName <0.4 zip location> <0.6 zip location>"
    exit 1
}

# Read the source and destination directories from the command line
$source_dir = $args[0]
$destination_dir = $args[1]
$has_updated = $false

## --FUNCTION DEFINITIONS--
function checked_move {
    param (
		$containing_folder,
        $source_subpath,
        $destination_subpath
    )
    
    $source_path = Join-Path $tempDirPointFour "${containing_folder}/${source_subpath}"
    $destination_path = Join-Path $tempDirPointSix "${containing_folder}/${destination_subpath}"
    
    #Print the move operation
    Write-Host "Copying from ${source_path} to ${destination_path}"
    
    # Move files
    try {
        Copy-Item -Path $source_path -Destination $destination_path -Force -ErrorAction Stop
        Write-Host "Files copied successfully."
    }
    catch {
        Write-Host "Error moving files"
        exit 1
    }
}

$perform_and_mark = { 
	param($inner_func)
	$inner_func.Invoke() #ideally with all arguments, but this one can't take any right now.
	$script:has_updated = $true
}

$ImgMove = {
	param($layout_name, $image_name)
	checked_move "img/ship/" "fm_gunhydra_${layout_name}_${image_name}.png" "zfm_gunhydra_${layout_name}_${image_name}.png"
}


$ShipMove = {
	param($layout_name)
	Write-Host "moving  ${layout_name} files"
	$ImgMove.Invoke($layout_name, "base")
	$ImgMove.Invoke($layout_name, "gib1")
	$ImgMove.Invoke($layout_name, "gib2")
	$ImgMove.Invoke($layout_name, "gib3")
	$ImgMove.Invoke($layout_name, "gib4")
	$ImgMove.Invoke($layout_name, "gib5")
	$ImgMove.Invoke($layout_name, "gib5")
	checked_move "img/customizeUI" "miniship_fm_gunhydra_${layout_name}.png" "miniship_zfm_gunhydra_${layout_name}.png"
}

$GBAMove = {
	$ShipMove.Invoke("a")
}

$GBBMove = {
	$ShipMove.Invoke("b")
}

$GBCMove = {
	$ShipMove.Invoke("c")
}

$GBEliteMove = {
	$ShipMove.Invoke("elite")
}

$GBFutureMove = {
	$ShipMove.Invoke("future")
}

$ship_move_body = {
	# Perform the move operation
	$confirmation = Read-Host "Change GunBom A? (y/n)"
	if ($confirmation -eq 'y') {
		$perform_and_mark.Invoke($GBAMove)
	}
	$confirmation = Read-Host "Change GunBom B? (y/n)"
	if ($confirmation -eq 'y') {
		$perform_and_mark.Invoke($GBBMove)
	}
	$confirmation = Read-Host "Change GunBom C? (y/n)"
	if ($confirmation -eq 'y') {
		$perform_and_mark.Invoke($GBCMove)
	}
	$confirmation = Read-Host "Change GunBom II? (y/n)"
	if ($confirmation -eq 'y') {
		$perform_and_mark.Invoke($GBEliteMove)
	}
	$confirmation = Read-Host "Change GunBom Future? (y/n)"
	if ($confirmation -eq 'y') {
		$perform_and_mark.Invoke($GBFutureMove)
	}
	if ($has_updated) {
		Write-Host "Retrofitting successful.  Gun Hydras are colorful again."
	} else {
		Write-Host "Oh. Ok."
	}
}

## --END FUNCTIONS--


# Create a temporary directory for unpacking
$tempDirPointFour = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
$tempDirPointSix = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())

New-Item -Path $tempDirPointFour -ItemType Directory

try { #todo fix the names for this, needs to be other things.
    # Step 1: Unpack both .zip files to temporary directories
    Expand-Archive -Path $source_dir -DestinationPath $tempDirPointFour
    Write-Host "Unpacked 0.4 files to $tempDirPointFour"
    Expand-Archive -Path $destination_dir -DestinationPath $tempDirPointSix
    Write-Host "Unpacked 0.6 files to $tempDirPointSix"

    # Step 2: Do the thing
    $ship_move_body.Invoke()

    # Step 3: Repack the fm 0.6 files.
	Write-Host "Repacking 0.6 files into $destination_dir"
    Compress-Archive -Path $tempDirPointSix\* -DestinationPath $destination_dir -Force
    Write-Host "Done."
}
finally {
    # Step 4: Clean up the temporary directory
    Remove-Item -Path $tempDirPointFour -Recurse -Force
}