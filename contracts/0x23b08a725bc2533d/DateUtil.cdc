// This contract was created for Tanabata contract

pub contract DateUtil {

    pub fun isJuly7(_ _unixTime: UFix64): Bool {
        let unixTime = Int(_unixTime)
        let secondsPerDay = 86400
        var days = unixTime / secondsPerDay

        let startYear = 1970
        var year = startYear
        var month = 1
        var day = 1

        while (days >= 365) {
            let daysInYear = DateUtil.isLeapYear(year) ? 366 : 365
            if (days >= daysInYear) {
                days = days - daysInYear
                year = year + 1
            } else {
                break
            }
        }

        while (days > 0) {
            let daysInMonth = self.getDaysInMonth(year, month)
            if (days >= daysInMonth) {
                days = days - daysInMonth
                month = month + 1
            } else {
                break
            }
        }

        day = day + days

        return month == 7 && day == 7
    }

    pub fun isLeapYear(_ year: Int): Bool {
        return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    pub fun  getDaysInMonth(_ year: Int, _ month: Int): Int {
        let daysInMonthMap = {
            1: 31,
            2: DateUtil.isLeapYear(year) ? 29 : 28,
            3: 31,
            4: 30,
            5: 31,
            6: 30,
            7: 31,
            8: 31,
            9: 30,
            10: 31,
            11: 30,
            12: 31
        }
        return daysInMonthMap[month]!
    }
}
