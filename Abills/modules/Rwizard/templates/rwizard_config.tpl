<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>

<div class='panel panel-primary form-horizontal'>
	<div class='panel-heading'>Reports Wizard</div>
	<div class='panel-body'>

		<div class='form-group'>
			<label class='control-element col-md-6'>_{NAME}_</label>
			<label class='control-element col-md-6'>_{GROUP}_</label>
			<div class='col-md-6'>
				<input type=text name=NAME value='%NAME%' class='form-control'>
			</div>
			<div class='col-md-6'>
				%GROUP_SEL%
			</div>
		</div>

		<div class='form-group'>
			<label class='control-element col-md-6'>_{QUERY}_: _{MAIN}_</label>
			<label class='control-element col-md-6'>_{QUERY}_: _{TOTAL}_</label>
			<div class='col-md-6'>
				<textarea class='form-control' name=QUERY rows=12 cols=75>%QUERY%</textarea>
			</div>
			<div class='col-md-6'>
				<textarea class='form-control' name=QUERY_TOTAL rows=12 cols=75>%QUERY_TOTAL%</textarea>
			</div>
		</div>

		<div class='form-group'>
			<div class='col-md-6'>
				<label class='control-element col-md-12'>_{FIELDS}_ (_{FIELD}_:_{NAME}_:CHART[LINE]:FILTER)</label>
				<div class='col-md-12'>
					<textarea class='form-control' name=FIELDS rows=12 cols=75>%FIELDS%</textarea>
				</div>
			</div>
			<div class='col-md-6'>
				<label class='control-element col-md-12'>_{COMMENTS}_</label>
				<div class='col-md-12'>
					<textarea class='form-control' name=COMMENTS rows=3 cols=75>%COMMENTS%</textarea>
				</div>
				<label class='control-element col-md-12'>_{IMPORT}_</label>
				<div class='col-md-12'>
					<input name=IMPORT id='IMPORT' type='file'>
				</div>
			</div>
		</div>

	</div>
	<div class='panel-footer'>
		<input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
	</div>
</div>

<!-- <table class=form>
<tr><th class=form_title>Reports Wizard</th></tr>
<tr><td>_{NAME}_</td></tr>
<tr><td><input type=text name=NAME value='%NAME%' size=75></td></tr>
<tr><td>_{COMMENTS}_</td></tr>
<tr><td><textarea name=COMMENTS rows=4 cols=75>%COMMENTS%</textarea></td></tr>
<tr><td>_{QUERY}_: _{MAIN}_</td></tr>
<tr><td><textarea name=QUERY rows=12 cols=75>%QUERY%</textarea></td></tr>
<tr><td>_{QUERY}_: _{TOTAL}_</td></tr>
<tr><td><textarea name=QUERY_TOTAL rows=8 cols=75>%QUERY_TOTAL%</textarea></td></tr>
<tr><td>_{FIELDS}_ (_{FIELD}_:_{NAME}_:CHART[LINE]:FILTER)</td></tr>
<tr><td><textarea name=FIELDS rows=5 cols=75>%FIELDS%</textarea></td></tr>
<tr><td>_{IMPORT}_: <input name=IMPORT id=IMPORT type=file></td></tr>
</table>


<input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
 -->
</FORM>