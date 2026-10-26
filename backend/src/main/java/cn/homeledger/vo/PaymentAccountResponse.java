package cn.homeledger.vo;

/**
 * 支付方式字典项（§4.2.1）。
 */
public record PaymentAccountResponse(Long id, String name, int sortNo, boolean isDefault, boolean enabled) {

}
