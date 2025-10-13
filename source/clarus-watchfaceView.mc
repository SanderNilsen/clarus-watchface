import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Lang;

class clarus_watchfaceView extends WatchUi.WatchFace {

    const DAY_ABBREVIATIONS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    const DAY_COUNT = 7;

    const BG_COLOR = Graphics.COLOR_BLACK;
    const FG_COLOR = Graphics.COLOR_WHITE;

    const TIME_FONTS = [
        Graphics.FONT_NUMBER_THAI_HOT,   // huge numeric
        Graphics.FONT_NUMBER_HOT,        // large numeric
        Graphics.FONT_NUMBER_MEDIUM,     // medium numeric
        Graphics.FONT_NUMBER_MILD,       // normal numeric
        Graphics.FONT_LARGE,             // fallback
        Graphics.FONT_MEDIUM,
        Graphics.FONT_SMALL
    ];

    // Smaller date font + tight spacing controls
    const DATE_FONT = Graphics.FONT_TINY;
    const DATE_SPACING_RATIO = 0.05; // % of time font height
    const DATE_MIN_SPACING   = 2.0;  // minimum pixels
    const DATE_NUDGE         = -1.0; // pull date 1px closer

    const TIME_MARGIN = 4;
    const SECONDS_RING_THICKNESS = 6.0;
    const SECONDS_RING_BASE_COLOR = Graphics.COLOR_DK_GRAY;
    const SECONDS_RING_ACTIVE_COLOR = Graphics.COLOR_RED;

    var mLastMinute;
    var mIsInSleep;

    function initialize() {
        WatchFace.initialize();
        mLastMinute = -1;
        mIsInSleep = false;
    }

    function onShow() as Void {
        mLastMinute = -1;
        mIsInSleep = false;
        if (!mIsInSleep) {
            WatchUi.requestUpdate();
        }
    }

    function onHide() as Void {
        mLastMinute = -1;
        mIsInSleep = true;
    }

    function onEnterSleep() as Void {
        mLastMinute = -1;
        mIsInSleep = true;
    }

    function onExitSleep() as Void {
        mLastMinute = -1;
        mIsInSleep = false;
        WatchUi.requestUpdate();
    }

    function onLayout(dc as Dc) as Void {}

    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();

        var minuteValue = clockTime.min;
        if (minuteValue != mLastMinute) {
            mLastMinute = minuteValue;
        }

        var width  = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2.0;
        var centerY = height / 2.0;

        dc.setColor(BG_COLOR, BG_COLOR);
        dc.clear();

        var seconds = clockTime.sec;
        if (seconds == null) { seconds = 0; }

        var minSide = (width < height) ? width : height;
        var maxRadius = minSide / 2.0 - TIME_MARGIN;
        if (maxRadius < 12.0) {
            var minSideAlt = (width < height) ? width : height;
            maxRadius = minSideAlt / 2.0 - 4.0;
        }
        var ringOuterRadius = maxRadius;
        var ringInnerRadius = ringOuterRadius - SECONDS_RING_THICKNESS;
        if (ringInnerRadius < 0.0) { ringInnerRadius = 0.0; }

        drawSecondsRing(dc, centerX, centerY, ringInnerRadius, ringOuterRadius, seconds);

        var timeParts = buildTimeParts(clockTime);
        var hourText = timeParts[0];
        var minuteText = timeParts[1];

        // Pick the largest font that fits using REAL text width (stable "88"+"88" probe)
        var timeFont = selectTimeFont(dc, width);

        var timeHeight = dc.getFontHeight(timeFont);
        var hourJustify   = Graphics.TEXT_JUSTIFY_RIGHT  | Graphics.TEXT_JUSTIFY_VCENTER;
        var minuteJustify = Graphics.TEXT_JUSTIFY_LEFT   | Graphics.TEXT_JUSTIFY_VCENTER;

        var dateText = buildDateString();
        var dateHeight = dc.getFontHeight(DATE_FONT);
        var dateJustify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        // Tighter gap between date and time
        var spacing = timeHeight * DATE_SPACING_RATIO;
        if (spacing < DATE_MIN_SPACING) { spacing = DATE_MIN_SPACING; }
        spacing = (spacing + DATE_NUDGE > 0.0) ? (spacing + DATE_NUDGE) : 0.0;

        var timeCenterY = height / 2.0;
        var dateCenterY = timeCenterY - (timeHeight / 2.0) - spacing - (dateHeight / 2.0);

        if (dateCenterY < dateHeight / 2.0) {
            var adjust = (dateHeight / 2.0) - dateCenterY;
            dateCenterY += adjust;
            timeCenterY += adjust;
        }

        if (timeCenterY > height - (timeHeight / 2.0)) {
            timeCenterY = height - (timeHeight / 2.0);
        }

        // Date (above)
        dc.setColor(FG_COLOR, BG_COLOR);
        dc.drawText(centerX, dateCenterY, DATE_FONT, dateText, dateJustify);

        // Time (hours in white, minutes in red)
        dc.setColor(FG_COLOR, BG_COLOR);
        dc.drawText(centerX, timeCenterY, timeFont, hourText, hourJustify);
        dc.setColor(Graphics.COLOR_RED, BG_COLOR);
        dc.drawText(centerX, timeCenterY, timeFont, minuteText, minuteJustify);

        // Keep if you want animated seconds ring; remove to save battery
        if (!mIsInSleep) {
            WatchUi.requestUpdate();
        }
    }

    function buildTimeParts(clockTime) {
        var hour = clockTime.hour;
        if (hour == null) { hour = 0; }

        var minute = clockTime.min;
        if (minute == null) { minute = 0; }

        var hourString = hour.format("%02d");
        var minuteString = minute.format("%02d");

        return [hourString, minuteString];
    }

    // Choose the largest font that fits using actual text measurement.
    // Use "88" probe so chosen size doesn't jump with different digits.
    function selectTimeFont(dc as Dc, width /* as Lang.Number */) {
        var maxWidth = width - (TIME_MARGIN * 2);
        var chosen = TIME_FONTS[TIME_FONTS.size() - 1]; // smallest fallback

        for (var i = 0; i < TIME_FONTS.size(); i += 1) {
            var f = TIME_FONTS[i];
            var dimsH = dc.getTextDimensions("88", f);
            var dimsM = dc.getTextDimensions("88", f);
            var total = dimsH[0] + dimsM[0]; // sum of widths

            if (total <= maxWidth) {
                chosen = f;
                break;
            }
        }
        return chosen;
    }

    function buildDateString() {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (info == null) { return ""; }

        // day_of_week: 1=Sun ... 7=Sat → convert to 0-based index
        var dow = info.day_of_week;
        if (dow == null) { dow = 1; } // default to Sunday
        var dayIndex = (dow - 1) % DAY_COUNT;
        if (dayIndex < 0) { dayIndex += DAY_COUNT; }

        var dayName = DAY_ABBREVIATIONS[dayIndex];
        var dayValue = info.day;
        if (dayValue == null || dayValue <= 0 || dayValue > 31) { dayValue = 1; }

        return dayName + " " + dayValue.format("%02d");
    }

    function drawSecondsRing(dc, centerX, centerY, innerRadius, outerRadius, seconds) {
        if (outerRadius <= 0.0) { return; }
        if (innerRadius < 0.0) { innerRadius = 0.0; }
        if (seconds < 0 || seconds > 59) { seconds = 0; }

        for (var i = 0; i < 60; i += 1) {
            var angle = (i / 60.0) * (2.0 * Math.PI) - (Math.PI / 2.0);
            var cosValue = Math.cos(angle);
            var sinValue = Math.sin(angle);

            var innerX = centerX + cosValue * innerRadius;
            var innerY = centerY + sinValue * innerRadius;
            var outerX = centerX + cosValue * outerRadius;
            var outerY = centerY + sinValue * outerRadius;

            if (i <= seconds) {
                dc.setColor(SECONDS_RING_ACTIVE_COLOR, BG_COLOR);
            } else {
                dc.setColor(SECONDS_RING_BASE_COLOR, BG_COLOR);
            }

            dc.drawLine(innerX, innerY, outerX, outerY);
        }
    }
}
