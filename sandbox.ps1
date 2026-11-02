#Requires -Version 7.0
<#
.SYNOPSIS
    Start the development sandbox and open a shell inside it (Windows).

.EXAMPLE
    .\sandbox.ps1
    .\sandbox.ps1 -Command build
    .\sandbox.ps1 -Command exec opencode
#>
[CmdletBinding()]
param(
    [ValidateSet('run', 'build', 'up', 'down', 'status', 'logs', 'exec', 'help')]
    [string]$Command = 'run',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Service = 'sandbox'

function Fail([string]$Message) {
    Write-Error $Message
    exit 1
}

function Invoke-Docker {
    & docker @args
    if ($LASTEXITCODE -ne 0) {
        Fail "docker $($args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

if ($Command -eq 'help') {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail 'Docker is not installed. See https://docs.docker.com/engine/install/'
}

& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Fail 'The Docker daemon is not reachable. Start Docker Desktop and retry.'
}

& docker compose version *> $null
if ($LASTEXITCODE -ne 0) {
    Fail 'docker compose v2 is required.'
}

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host '==> Created .env from .env.example. Add your tokens, then run this script again.'
}

$envContent = Get-Content .env -Raw
if ($envContent -notmatch '(?m)^GITHUB_PERSONAL_ACCESS_TOKEN=.+') {
    Write-Warning 'GITHUB_PERSONAL_ACCESS_TOKEN is empty: /plan-item and /implement-item cannot read or comment on issues.'
}
if ($envContent -notmatch '(?m)^(ANTHROPIC_API_KEY|OPENAI_API_KEY|GEMINI_API_KEY)=.+') {
    Write-Warning "No provider API key in .env. You can still log in interactively with 'opencode /connect' or 'claude'."
}

switch ($Command) {
    'run' {
        Invoke-Docker compose up -d
        Invoke-Docker compose exec $Service sh -l
    }
    'build' {
        Invoke-Docker compose up -d --build
        Invoke-Docker compose exec $Service sh -l
    }
    'exec' {
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Fail 'usage: .\sandbox.ps1 -Command exec <command> [args...]'
        }
        Invoke-Docker compose up -d
        Invoke-Docker compose exec $Service @Arguments
    }
    'up' {
        Invoke-Docker compose up -d
    }
    'down' {
        Invoke-Docker compose down
    }
    'status' {
        Invoke-Docker compose ps
    }
    'logs' {
        Invoke-Docker compose logs -f $Service
    }
}
