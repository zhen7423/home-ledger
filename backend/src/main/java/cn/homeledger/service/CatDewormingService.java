package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.CatDewormingCreateRequest;
import cn.homeledger.dto.CatDewormingUpdateRequest;
import cn.homeledger.vo.CatDewormingResponse;

/**
 * §4.3.3 体内外驱虫记录。
 * <p>
 * 这里没有「按 id 取一条」：编辑表单从列表里回填，而列表本来就不分页。多一条端点只是多一处
 * 与列表口径可能不一致的答案。
 */
public interface CatDewormingService {

	/**
	 * @param catId 可空，空表示全家庭
	 */
	List<CatDewormingResponse> list(Long catId);

	CatDewormingResponse create(Long userId, CatDewormingCreateRequest request);

	CatDewormingResponse update(Long userId, Long id, CatDewormingUpdateRequest request);

	void delete(Long userId, Long id);

}
