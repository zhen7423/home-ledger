package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 区间内某一天的支出（§4.2.6）。区间内每一天都有一项，没有支出的补 0——补 0 在服务端做完，
 * 前端拿到就能直接画，不必自己算「这个月有几天」。
 */
public record DailyPoint(@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate date,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal expense) {

}
