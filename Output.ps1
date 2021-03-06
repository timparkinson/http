﻿# posh-httpd Output functions
function Register-HTTPOutputType {

    process {
        if (-not ("HTTPOutput" -as [type])) {
            Write-Verbose -Message "Registering HTTPOutput type"
            
            Add-Type -TypeDefinition @"
            using System;
            using System.Net;
            using System.IO;
             
            public class HTTPOutput
            {
                public String ContentType;

                public HttpStatusCode StatusCode;

                public Object Content;
            }
"@
        }        
    }
}

function ConvertTo-HTTPOutput {
    [CmdletBinding()]

    param(
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )

    begin {
        Register-HTTPOutputType
    }

    end {
        $output = New-Object HTTPOutput
        if (-not $InputObject) {
            $output.StatusCode = [System.Net.HttpStatusCode]::InternalServerError
        } else {
            switch ($InputObject.GetType().Name) {
                'HTTPOutput' {
                    $output = $InputObject
                }

                'Hashtable' {
 
                    if ($InputObject.StatusCode) {
                        
                        $output.StatusCode = $InputObject.StatusCode
                        $set_something = $true
                    }

                    if ($InputObject.Content) {
                        
                        $output.Content = $InputObject.Content
                        $set_something = $true
                    }

                    if ($InputObject.ContentType) {
                        
                        $output.ContentType = $InputObject.ContentType
                        $set_something = $true
                    }

                    if (-not $set_something) {
                        
                        $output.content = $InputObject | Out-String                    
                    }

                }

                default {
                    
                    if ($InputObject.GetType().BaseType.ToString() -eq  'System.IO.Stream') {
                            $output.Content = $InputObject
                    } elseif ($Input){
                        #$Input.reset()
                        $output.Content = @($Input) | Out-String
                    } else {
                        $output.Content = $InputObject | Out-String
                    }
                }
            }
        
        }

        if (-not $output.ContentType) {
            $output.ContentType = 'text/html'
        }

        if ($output.StatusCode.ToString() -eq '0') {
            $output.StatusCode = [System.Net.HttpStatusCode]::OK
        }

        $output
    }
}