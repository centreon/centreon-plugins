package notification::email::templates::style;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(get_css);

sub get_css {
return q{
<style type="text/css">
#outlook a {
  padding: 0;
}

.ReadMsgBody {
  width: 100%;
}

.ExternalClass {
  width: 100%;
}

.ExternalClass * {
  line-height: 100%;
}

body {
  margin: 0;
  padding: 0;
  -webkit-text-size-adjust: 100%;
  -ms-text-size-adjust: 100%;
}

table,
td {
  border-collapse: collapse;
  mso-table-lspace: 0pt;
  mso-table-rspace: 0pt;
}

img {
  border: 0;
  height: auto;
  line-height: 100%;
  outline: none;
  text-decoration: none;
  -ms-interpolation-mode: bicubic;
}

p {
  display: block;
  margin: 13px 0;
}
</style><!--[if !mso]><!-->
<style type="text/css">
@media only screen and (max-width:480px) {
  @-ms-viewport {
    width: 320px;
  }

  @viewport {
    width: 320px;
  }
}
</style><!--<![endif]--><!--[if mso]>
    <xml>
    <o:OfficeDocumentSettings>
      <o:AllowPNG/>
      <o:PixelsPerInch>96</o:PixelsPerInch>
    </o:OfficeDocumentSettings>
    </xml>
    <![endif]--><!--[if lte mso 11]>
    <style type="text/css">
      .outlook-group-fix { width:100% !important; }
    </style>
    <![endif]--><!--[if !mso]><!-->
<link href="https://fonts.googleapis.com/css?family=Open+Sans:300,400,500,700" rel="stylesheet" type="text/css">
<style type="text/css">
@import url(https://fonts.googleapis.com/css?family=Open+Sans:300,400,500,700);
</style><!--<![endif]-->
<style type="text/css">
@media only screen and (min-width:480px) {
  .mj-column-per-100 {
    width: 100% !important;
    max-width: 100%;
  }

  .mj-column-per-20 {
    width: 20% !important;
    max-width: 20%;
  }

  .mj-column-per-60 {
    width: 60% !important;
    max-width: 60%;
  }

  .mj-column-per-33 {
    width: 33.333333333333336% !important;
    max-width: 33.333333333333336%;
  }
}
</style>
<style type="text/css">
@media only screen and (max-width:480px) {
  table.full-width-mobile {
    width: 100% !important;
  }

  td.full-width-mobile {
    width: auto !important;
  }
}
</style>
<style type="text/css">
.notification-box {
  color: #333;
  padding: 20px;
  border: 1px solid #ccc;
  background-color: #f9f9f9;
  margin: 0 auto !important;
}

.header {
  background-color: <TMPL_VAR NAME="backgroundColor" >;
  padding: 0px;
  margin-bottom: 15px !important;
}

.font-header div {
  font-size: 24px !important;
  color: <TMPL_VAR NAME="textColor" > !important;
}

@media (max-width:480px) {
  .font-header div {
    font-size: 15px !important;
  }
}

.content {
  margin-top: 0px;
  padding: 0px 0px !important;
}

.status {
  color: <TMPL_VAR NAME="stateColor" >;
  font-weight: bold;
  font-size: 20px;
}

.status-info {
  padding: 5px;
  margin: 10px 0;
  background-color: white;
  border-left: 3px solid <TMPL_VAR NAME="stateColor" >;
}

.info-resources {
  background-color: #ddd;
  padding: 0px;
  color: #666;
}

p {
  padding: 0px;
  margin-bottom: 0px;
  margin-top: 0px;
  color: black;
}

.dynamic {
  padding-top: 0px;
  font-weight: bold;
  margin-bottom: 10px;
  color: black;
}

.button a {
  display: inline-block;
  padding: 5px 10px;
  border-radius: 5px;
  width: 100%;
}

@media (max-width:480px) {
  .button a {
    font-size: 9px !important;
  }
}

.graph-container {
  background-color: #f9f9f9;
  border: 1px solid #ccc;
  padding: 15px;
  margin-top: 20px;
}
</style>
};
}

1;