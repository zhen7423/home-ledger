package cn.homeledger.vo;

import java.math.BigDecimal;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 类别占比的一片（§4.2.6）。同一个 record 既表示大类也表示它下面的一片小类，靠 subCategories 空不空区分。
 * <p>
 * categoryId 为 null 只有一种含义：Top 8 之外合并出来的「其他」。它不是一片真的类别，
 * 所以 subCategories 恒为空列表，前端要据此禁掉它的下钻。
 * <p>
 * 作为小类出现时，categoryId 装的是<b>小类的 id</b>，percent 是<b>相对父大类</b>的占比而不是相对总支出
 * ——下钻看到的饼图就该加起来是 100%。
 */
public record CategorySlice(Long categoryId, String name,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount, int percent,
		List<CategorySlice> subCategories) {

}
