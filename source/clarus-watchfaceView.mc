import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

class clarus_watchfaceView extends WatchUi.WatchFace {

    const DAY_ABBREVIATIONS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    const DAY_COUNT = 7;

    const BG_COLOR = Graphics.COLOR_BLACK;
    const FG_COLOR = Graphics.COLOR_WHITE;
    const TIME_FONT_OPTIONS = [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL];
    const DATE_FONT = Graphics.FONT_SMALL;
    const TIME_MARGIN = 8;

    var mLastMinute;

    function initialize() {
        WatchFace.initialize();
        mLastMinute = -1;
    }

    function onShow() as Void {
        mLastMinute = -1;
    }

    function onHide() as Void {
        mLastMinute = -1;
    }

    function onEnterSleep() as Void {
        mLastMinute = -1;
    }

    function onExitSleep() as Void {
        mLastMinute = -1;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();

        // clockTime is guaranteed to be non-null, so no need to check for null.

        var minuteValue = clockTime.min;
        // No need to check for null as minuteValue is guaranteed to be non-null.

        if (minuteValue == mLastMinute) {
            return;
        }

        mLastMinute = minuteValue;

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2.0;
        var centerY = height / 2.0;

        dc.setColor(BG_COLOR, BG_COLOR);
        dc.clear();

        var timeParts = buildTimeParts(clockTime);
        var hourText = timeParts[0];
        var minuteText = timeParts[1];

        var timeFont = selectTimeFont(dc, width, hourText + minuteText);
        var timeHeight = dc.getFontHeight(timeFont);
        var hourJustify = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
        var minuteJustify = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        var dateText = buildDateString();
        var dateHeight = dc.getFontHeight(DATE_FONT);
        var dateJustify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var spacing = 12.0;

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

        dc.setColor(FG_COLOR, BG_COLOR);
        dc.drawText(centerX, dateCenterY, DATE_FONT, dateText, dateJustify);

        dc.setColor(FG_COLOR, BG_COLOR);
        dc.drawText(centerX, timeCenterY, timeFont, hourText, hourJustify);
        dc.setColor(Graphics.COLOR_RED, BG_COLOR);
        dc.drawText(centerX, timeCenterY, timeFont, minuteText, minuteJustify);

    }

    function buildTimeParts(clockTime) {
        var hour = clockTime.hour;
        if (hour == null) {
            hour = 0;
        }

        var minute = clockTime.min;
        if (minute == null) {
            minute = 0;
        }

        var hourString = hour.format("%02d");
        var minuteString = minute.format("%02d");

        return [hourString, minuteString];
    }

    function selectTimeFont(dc, width, text) {
        var maxWidth = width - (TIME_MARGIN * 2);
        var chosenFont = TIME_FONT_OPTIONS[TIME_FONT_OPTIONS.size() - 1];

        var count = TIME_FONT_OPTIONS.size();
        for (var i = 0; i < count; i += 1) {
            var font = TIME_FONT_OPTIONS[i];
            var textWidth = estimateTextWidth(dc, font, text);

            if (textWidth <= maxWidth) {
                chosenFont = font;
                break;
            }
        }

        return chosenFont;
    }

    function estimateTextWidth(dc, font, text) {
        var fontHeight = dc.getFontHeight(font);
        var charCount = text.length();
        if (charCount <= 0) {
            return 0;
        }

        var approxWidth = charCount * fontHeight * 6 / 10;
        return approxWidth;
    }

    function buildDateString() {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

        if (info == null) {
            return "";
        }

        var dayIndex = info.day_of_week;
        if (dayIndex == null) {
            dayIndex = 0;
        } else {
            dayIndex = dayIndex % DAY_COUNT;
        }

        if (dayIndex < 0) {
            dayIndex = 0;
        }

        var dayName = DAY_ABBREVIATIONS[dayIndex];
        var dayValue = info.day;

        if (dayValue == null || dayValue <= 0 || dayValue > 31) {
            dayValue = 1;
        }

        var dayString = dayValue.format("%02d");

        return dayName + " " + dayString;
    }
}
