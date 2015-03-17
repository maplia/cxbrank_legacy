/******************************************************************************************************
* 「テキストフォームの内容をクッキーに保存」
*  著作者：インターネットコミュニティ
*  このプログラムはフリーウェアです、この文書を消さなければご自由にお使いいただいて結構です
*  www.internetcommunity.jp
*  www.cityjp.com
*  webmaster@cityjp.net
******************************************************************************************************/
var ReserveDay = 10;

//クッキー取得処理
function getCookie(cName) {
	var Cookies = document.cookie.replace(/ /g,'');
	var Cookie = Cookies.split(';');
	var Ret_C = '';
	for (i in Cookie){
		if (Cookie[i].indexOf('=') < 0){
			Cookie[i]+='=';
		}
		Chop_C = Cookie[i].split('=');
		if (Chop_C[0] == escape(cName)){
			Ret_C = unescape(Chop_C[1]);
			break;
		}
	}
	return Ret_C;
}
//クッキー登録処理
function setCookie(pName,pValue) {
	if(pValue != null){
		var setDay = new Date();
		setDay.setTime(setDay.getTime() + (ReserveDay * 86400000));
		expDay = setDay.toGMTString().replace(/UTC/,'GMT');
		document.cookie = escape(pName) + '=' + escape(pValue) + ';expires='+expDay;
		return true;
	}
	return false;
}
