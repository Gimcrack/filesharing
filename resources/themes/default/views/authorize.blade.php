@extends('master')

@section('page', 'download')

@section('content')

	<style>
		.form-label {
			font-size:18px;
			font-weight:bold;
		}

		.form-control {
			width: 100%;
			padding: 1em;
			border-radius: 12px;
			font-size:30px;
			font-family:"Courier New";
			margin-bottom: 1em;
		}

		.form-btn {
			padding: 0.5em 1em;
			border-radius: 12px;
			font-size: 24px
		}

		form {
			padding: 1em;
		}
	</style>
	<form method="POST" action="{{ ($download) ? route('bundle.download',['bundle' => $bundle_id]) : route('bundle.preview',['bundle' => $bundle_id]) }}">
		<label class="form-label" for="">Please enter your access id</label>
		<input autofocus class="form-control" type="password" name="access_id" placeholder="Access Id">

		<label class="form-label" for="">Please enter your authorization code</label>
		<input autofocus class="form-control" type="password" name="auth" placeholder="Authorization Code">

		<button class="form-btn" type="submit">{{ ($download) ? "Download Files" : "Preview Files" }}</button>
	</form>
@endsection
