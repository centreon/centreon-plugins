package notification::email::templates::metaservice;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(get_metaservice_template);

sub get_metaservice_template {
return q{
<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml"
    xmlns:o="urn:schemas-microsoft-com:office:office">

<head>
    <title></title><!--[if !mso]><!-- -->
    <meta http-equiv="X-UA-Compatible" content="IE=edge"><!--<![endif]-->
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">

    <TMPL_VAR NAME="dynamicCss">
</head>

<body>
  <div>
    <!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="notification-box-outlook" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
    <div class="notification-box" style="Margin:0px auto;max-width:600px;">
      <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
        <tbody>
          <tr>
            <td style="direction:ltr;font-size:0px;padding:20px 0;text-align:center;vertical-align:top;">
              <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="header-outlook" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="header-outlook" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div class="header" style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:0;line-height:0;text-align:left;display:inline-block;width:100%;direction:ltr;">
                          <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td style="vertical-align:top;width:120px;" ><![endif]-->
                          <div class="mj-column-per-20 outlook-group-fix"
                            style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:20%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td><td style="vertical-align:top;width:360px;" ><![endif]-->
                          <div class="mj-column-per-60 outlook-group-fix font-header"
                            style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:60%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                      <tr>
                                        <td align="center" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                          <div
                                            style="font-family:CoconPro-BoldCond, Red Hat Display, Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:center;color:#000000;">
                                            <TMPL_VAR NAME="type"></div>
                                        </td>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td><td style="vertical-align:top;width:120px;" ><![endif]-->
                          <div class="mj-column-per-20 outlook-group-fix font-header"
                            style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:20%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                      <tr>
                                        <td align="right" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                          <div style="font-family:CoconPro-BoldCond, Red Hat Display , Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:right;color:#000000;">
                                            <TMPL_VAR NAME="attempts">/<TMPL_VAR NAME="maxAttempts">
                                            </div>
                                        </td>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td></tr></table><![endif]-->
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="info-resources-outlook" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="info-resources-outlook" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div class="info-resources" style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                            <tbody>
                              <tr>
                                <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tr>
                                      <td align="left" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                        <div
                                          style="font-family:CoconPro-BoldCond, Red Hat Display , Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">
                                          <p>Meta Service:</p>
                                          <p class="dynamic">
                                          <TMPL_VAR NAME="serviceDescription"> 
                                            <span style="font-weight: normal">is</span> 
                                            <span class="status">
                                                <TMPL_VAR NAME="status">
                                            </span> 
                                            <span style="font-weight: normal">for:</span>
                                            <span>
                                                <TMPL_VAR NAME="duration">
                                            </span>
                                            </p>
                                        </div>
                                      </td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:0;line-height:0;text-align:left;display:inline-block;width:100%;direction:ltr;">
                          <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td style="vertical-align:top;width:200px;" ><![endif]-->
                          <div class="mj-column-per-33 outlook-group-fix"
                            style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:33%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                      <tr>
                                        <td align="left" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                          <div
                                            style="font-family:CoconPro-BoldCond, Red Hat Display , Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">
                                            <p>Date:</p>
                                            <p class="dynamic">
                                                <TMPL_VAR NAME="date">
                                            </p>
                                          </div>
                                        </td>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td><td style="vertical-align:top;width:200px;" ><![endif]-->
                          <div class="mj-column-per-33 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:33%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td><td style="vertical-align:top;width:200px;" ><![endif]-->
                          <div class="mj-column-per-33 outlook-group-fix"
                            style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:33%;">
                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                              <tbody>
                                <tr>
                                  <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                      <tr>
                                        <td align="center" vertical-align="middle" class="button"
                                          style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                          <table border="0" cellpadding="0" cellspacing="0" role="presentation"
                                            style="border-collapse:separate;line-height:100%;">
                                            <tr>
                                              <td align="center" bgcolor="#008CBA" role="presentation"
                                                style="border:none;border-radius:3px;cursor:auto;padding:0px;background:#008CBA;"
                                                valign="middle">
                                                <a href="<TMPL_VAR NAME='dynamicHref'>"
                                                  style="background:#008CBA;color:#ffffff;font-family:CoconPro-BoldCond, Red Hat Display, Open Sans , Verdana , sans-serif;font-size:15px;font-weight:normal;line-height:120%;Margin:0;text-decoration:none;text-transform:none;"
                                                  target="_blank">More Information</a></td>
                                            </tr>
                                          </table>
                                        </td>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                              </tbody>
                            </table>
                          </div><!--[if mso | IE]></td></tr></table><![endif]-->
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <TMPL_IF NAME="includeAuthor">
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                            <tbody>
                              <tr>
                                <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tr>
                                      <td align="left" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                        <div style="font-family:CoconPro-BoldCond, Red Hat Display, Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">
                                          <p>
                                            <TMPL_VAR NAME="eventType"> by:
                                          </p>
                                          <p class="dynamic">
                                            <TMPL_VAR NAME="author">
                                          </p>
                                        </div>
                                      </td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </TMPL_IF>
            <TMPL_IF NAME="includeComment">
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                            <tbody>
                              <tr>
                                <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tr>
                                      <td align="left" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                        <div 
                                          style="font-family:CoconPro-BoldCond, Red Hat Display, Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">
                                          <p>
                                          <TMPL_VAR NAME="eventType"> Comment:
                                          </p>
                                          <p class="dynamic">
                                            <TMPL_VAR NAME="comment">
                                          </p>
                                        </div>
                                      </td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
</TMPL_IF>
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="status-info-outlook" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="status-info-outlook" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div class="status-info" style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                            <tbody>
                              <tr>
                                <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tr>
                                      <td align="left" style="font-size:0px;padding:0px 5px;word-break:break-word;">
                                        <div
                                          style="font-family:CoconPro-BoldCond, Red Hat Display , Open Sans , Verdana , sans-serif;font-size:15px;line-height:1;text-align:left;color:#000000;">
                                          <p>Status information:</p>
                                          <p class="dynamic">
                                            <TMPL_VAR NAME="output">
                                           </p>
                                        </div>
                                      </td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <!--[if mso | IE]></td></tr></table></td></tr><tr><td class="" width="600px" ><table align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]-->
              <div style="Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
                  style="width:100%;">
                  <tbody>
                    <tr>
                      <td
                        style="direction:ltr;font-size:0px;padding:5px 0px 5px 0px;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix"
                          style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                            <tbody>
                              <tr>
                                <td style="vertical-align:top;padding:0px 0px 0px 0px;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tr>
                                      <td align="center" class="graph-container"
                                        style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                        <table border="0" cellpadding="0" cellspacing="0" role="presentation"
                                          style="border-collapse:collapse;border-spacing:0px;">
                                          <tbody>
                                            <tr>
                                              <td style="width:550px;">
                                                <TMPL_VAR NAME="graphHtml">
                                              </td>
                                            </tr>
                                          </tbody>
                                        </table>
                                      </td>
                                    </tr>
                                  </table>
                                </td>
                              </tr>
                            </tbody>
                          </table>
                        </div><!--[if mso | IE]></td></tr></table><![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div><!--[if mso | IE]></td></tr></table></td></tr></table><![endif]-->
            </td>
          </tr>
        </tbody>
      </table>
    </div><!--[if mso | IE]></td></tr></table><![endif]-->
  </div>
</body>

</html>
};
}

1;