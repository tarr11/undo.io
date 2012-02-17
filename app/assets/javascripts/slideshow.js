/**
 * Created by JetBrains RubyMine.
 * User: dougt
 * Date: 2/15/12
 * Time: 2:49 PM
 * To change this template use File | Settings | File Templates.
 */
jQuery.fn.center = function () {
    this.css("position","absolute");
    this.css("top", (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop() + "px");
    this.css("left", (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft() + "px");
    return this;
}


jQuery.fn.nextSlide = function (nextPrev) {
    var results = $('.slide:visible');
    var slideToShow = [];

    var slideAdd = 1;
    if (nextPrev == 'prev')
    {
        slideAdd = -1;
    }

    if (results.length > 0)
    {
        slideToShow = $('#slide' + (Number(results.first().attr('slide-id')) + slideAdd))
    }

    $('.slide').hide();
    if (slideToShow.length > 0)
    {
        slideToShow.show();
    }
    else
    {
        $('.slideshow').hide();
    }

}

