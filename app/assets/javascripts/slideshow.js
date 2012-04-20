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
    var slide_number = Number($('.slideshow-foreground').data("slide_number"))
    var slideToShow = [];

    var slideAdd = 1;
    if (nextPrev == 'prev')
    {
        slideAdd = -1;
    }

    var next_slide = slide_number + slideAdd;

    var slide_id = 'slide' + next_slide;
    slideToShow = $('#' + slide_id)

    if (slideToShow.length > 0)
    {
        $('.slideshow-foreground').html('')
        $('.slideshow-foreground').append(slideToShow.clone())
        $('.slideshow-foreground').data("slide_number",next_slide)
        window.location.hash = '#'  + slide_id
//slideToShow.show();
    }
    else
    {
        $('.slideshow').hide();
        window.location.hash = ''
    }

}



