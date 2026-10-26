package cn.homeledger.dto;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

/**
 * 支付方式拖拽排序（§4.2.1）。orderedIds 按新顺序排开，服务端把 sort_no 重写为 1…n。
 */
public record PaymentAccountSortRequest(@NotNull @NotEmpty(message = "排序列表不能为空") List<Long> orderedIds) {

}
