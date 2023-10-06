<#

.SYNOPSIS
Retrieve a telephone report for a specified period of time. 

.DESCRIPTION
Retrieve a telephone report for a specified period of time.

.PARAMETER From
Start date.

.PARAMETER To
End date.

.PARAMETER PageSize
The number of records returned within a single API call.


.PARAMETER NextPageToken
token to receive the next page of a resultset.

.PARAMETER CombineAllPages
If a report has multiple pages this will loop through all pages automatically and place all telephony usage found 
from each page into the telephony_usage field of the report generated. The page size is set automatically to 300.

.EXAMPLE
Get-ZoomPhoneCharges -from '2019-07-01' -to '2019-07-31' -page 1 -pagesize 300
Get-ZoomPhoneCharges -ytd

.OUTPUTS
A hastable with the Zoom API response.

#>

function Get-ZoomPhoneCharges {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(
            Mandatory = $True, 
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'Default'
        )]
        [Parameter(ParameterSetName = 'CombineAllPages')]
        [datetime]$From,

        [Parameter(
            Mandatory = $True, 
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'Default'
        )]
        [Parameter(ParameterSetName = 'CombineAllPages')]
        [datetime]$To,

        [Parameter(ParameterSetName = 'CombineAllPages')]
        [switch]$CombineAllPages,

        [Parameter(
            ValueFromPipelineByPropertyName = $True,
            ParameterSetName = 'Default'
        )]
        [ValidateRange(1, 300)]
        [Alias('size', 'page_size')]
        [int]$PageSize = 30,        
		
		[Parameter(
            ParameterSetName = 'Default'
        )]        		
		[Alias('NextPageToken')]
        [string]$npt
    )

    begin {
        if ($From) {
            [string]$From = $From.ToString('yyyy-MM-dd')
        }
        if ($To){
            [string]$To = $To.ToString('yyyy-MM-dd')
        }
        
    }

    process {
        if ($PsCmdlet.ParameterSetName -eq 'CombineAllPages') {
                $InitialReport = Get-ZoomPhoneCharges -From $From -To $To -PageSize 300                 
                $CombinedReport = [PSCustomObject]@{
                    From                  = $From
                    To                    = $To
                    Page_count            = $InitialReport.page_count
                    Total_records         = $InitialReport.total_records
                    call_charges          = $InitialReport.call_charges
                }
    								
				$next_token = $InitialReport.next_page_token				
				while ($null -ne $next_token) {											
						$nextReport = (Get-ZoomPhoneCharges -From $From -To $To -PageSize 300 -npt $next_token)
					    $call_charges = $nextReport.call_charges
                        $CombinedReport.call_charges += $call_charges
						$CombinedReport.Page_count += 1
						$CombinedReport.Total_records += $nextReport.total_records
						$next_token = $nextReport.next_page_token																
                }
    
                Write-Output $CombinedReport
        } else {            			
			$request = [System.UriBuilder]"https://api.$ZoomURI/v2/phone/reports/call_charges"
						
            $query = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)              
            $query.Add('from', $From)
            $query.Add('to', $To)
            $query.Add('page_size', $PageSize)            
			if ($null -ne $npt) {
				$query.Add('next_page_token', $npt)
			} 
            $Request.Query = $query.ToString()
			
            $response = Invoke-ZoomRestMethod -Uri $request.Uri -Method GET
            
            Write-Output $response
        }
    }
}