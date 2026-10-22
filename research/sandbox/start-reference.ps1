$ErrorActionPreference = 'Stop'
$docker = (Get-Command docker -ErrorAction Stop).Source
$network = 'oregon-reference-isolated'
$container = 'oregon-reference-study'
$networks = & $docker network ls --format '{{.Name}}'
if ($network -notin $networks) {
    & $docker network create --internal --label purpose=oregon-reference $network
    if ($LASTEXITCODE -ne 0) { throw 'Could not create reference network' }
}
$internal = & $docker network inspect $network --format '{{.Internal}}'
if ($internal -ne 'true') { throw 'Reference network must be internal' }
$existing = & $docker ps -a --format '{{.Names}}'
if ($container -in $existing) { throw 'Reference container already exists; inspect it instead of overwriting it.' }
& $docker run -d --name $container --label purpose=oregon-reference `
    --network $network `
    --cap-drop ALL --security-opt no-new-privileges:true --read-only `
    --tmpfs /tmp:rw,size=1g,mode=1777 `
    --tmpfs /home/wine:rw,size=2g,uid=1000,gid=1000,mode=0700 `
    --shm-size 256m --memory 3g --cpus 2 --pids-limit 512 `
    oregon-reference-wine:local
if ($LASTEXITCODE -ne 0) { throw 'Could not start reference container' }
$relay = 'oregon-reference-desktop'
if ($relay -in $existing) { throw 'Desktop relay already exists; inspect it instead of overwriting it.' }
& $docker run -d --name $relay --label purpose=oregon-reference `
    --network bridge --publish 127.0.0.1:6090:6080 `
    --cap-drop ALL --security-opt no-new-privileges:true --read-only `
    --memory 128m --cpus 0.5 --pids-limit 64 oregon-reference-desktop:local
if ($LASTEXITCODE -ne 0) { throw 'Could not start desktop relay' }
& $docker network connect $network $relay
if ($LASTEXITCODE -ne 0) { throw 'Could not attach desktop relay' }
Write-Output 'Desktop: http://127.0.0.1:6090/vnc.html?autoconnect=1&resize=off'
Write-Output 'The installer is not launched automatically.'
